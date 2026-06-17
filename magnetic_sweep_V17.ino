/// Título: magnetic_sweep_V10
/// Descripción:
/// * V7: Controla el generador de señales sinusoidales a través del puerto serie con dos sencillas funciones con instrucciones en binario.
/// * V8: Se implementa el multitasking para controlar los indicadores LED.
/// * V8: Se implementa la interfaz de indicadores LED y zumbador.
/// * V9: Se implementa el control de los DAC.
/// * V10: Ligera mejora del control del DAC y el generador para poder hacer barridos manteniendo frecuencia o Hdc constantes.
/// * V11: Se implementa el control del digipot.
/// * V11: Se implementa recogida de errores de resolución y rango de frecuencia, campo H continuo y campo H alterno.
/// * V12: Se implementa recolección de datos a través del ADC.
/// * V13: Se implementan melodías en lugar de pitidos.
/// * V14: Se han ajustado los periodos de cambio de frecuencia y muestreo.
/// * V14: Se ha hecho un ajuste en los bucles de f y Hdc, ya que no llegaban nunca a tomar medidas con los valores máximos.
/// * V15: Se implementa la recogida de más errores de resolución y rango de frecuencia y campo H continuo.
/// * V15: Las variables samples_per_f y sample_period son ahora parámetros de entrada.
/// * V16: El primer parámetro de entrada pasa a ser una cadena de caracteres que indica el comando. Entradas admitidas, cmd="sweep","params"
/// * V17: Añadido los comandos cmd="man" para control manual y cmd="raw" para control a través de los valores en crudo de registros.

// Los comandos de entrada del microcontrolador tendrán siempre los mismos 8 parámetros separados por espacios:
// char[10] cmd    float f_min    float f_max    float f_step    float Hdc_min    float Hdc_max    float Hdc_step    H0_1Hz
// Si cmd="sweep" --> se pone en marcha el sistema magnético con los parámetros indicados; Si cmd = "params" --> El microcontrolador devuelve los parámetros de calibración guardados en su memoria.


// Ejemplo de comando:
// 0 50000 65000 1000 0 2 1 0.15 50000

#include <SPI.h>

// Parámetros de calibración
// >>Nota: El usuario debe ajustar estos valores en función de los componentes empleados y la calibración realizada mediante potenciómetros.
const float f_MCLK = 24*pow(10,6); // Hz // Introducir frecuencia del oscilador externo del generador de señal AD9833.
const float R = 104; // Ohms // Introducir valor de resistencia de carga.
const float L = 0.00762; // Henrios // Introducir valor de inductancia del solenoide primario.
const float k = 118.48; // 1/m // Introducir constante de solenoide del solenoide primario.
const float Voffset = -0.046;//345; // Volts // Introducir tensión medida con el generador en modo reposo y los DACs apagados.
//const float Vdc1_max = 1.945; // Volts // Introducir tensión máxima medida con DAC1 (DAC2=0).
//const uint8_t DAC2_min = 255; // Introducir valor del DAC1 en escala de 8 bits al medir la tensión máxima.
const float Vdc2_min = -7.3; // Volts // Introducir tensión mínima medida con DAC2 (DAC1=0).
const uint8_t DAC2_min = 255; // Introducir valor del DAC2 en escala de 8 bits al medir la tensión mínima.
const float Vdc1_max = 0.055; // Volts // Introducir con que aporte míninimo de tensión de DAC1 se iguala o supera al Voffset o -kv2. Es decir, Vdc1 mínimo para que: Vdc1>=Voffset o Vdc1>=(-kv2). Este será el aporte máximo de Vdc1 que empleará este programa.
const uint8_t DAC1_max = 3; // Introducir valor del DAC1 en escala de 8 bits al medir la tensión anterior. Este será el valor de DAC máximo que empleará este programa.
const float Vac0 = 0.92; // Volts // Introducir amplitud de tensión medida en la salida cuando digipot=0;
const float Vac_max = 7.4; // Volts // Introducir amplitud de tensión máxima medida en la salida.
const uint8_t digipot_max = 180; // Introducir valor de entrada del digipot en escala de 8 bits al medir la tensión anterior.
const float Vac_punto = 2.6; // Volts // Introducir amplitud de tensión medida en la salida para un valor intermedio del digipot.
const uint8_t digipot_punto = 50; // Introducir valor de entrada del digipot en escala de 8 bits al medir la tensión anterior.

// Parámetros derivados de los parámetros de calibración introducidos.
// >> Nota: Los cálculos y funciones se han hecho suponiendo que DAC2 es coarse tuning (ya que depende únicamente de una de las resistencias variables) y que DAC1 es para fine tuning, por lo que Hdc estará en el rango negativo. A partir de ahora cada vez que se mencione Hdc se estará refiriendo a su módulo.
const float clock_constant = pow(2,28) / f_MCLK; // s // Constante de proporcionalidad que determina el valor requerido en el registro de frecuencia para lograr una determinada frecuencia de salida.
const float f_step_min = 1/clock_constant; // Hz // Resolución de frecuencia del generador de señal.
const float kv2 = (Vdc2_min+Voffset)/DAC2_min; // Volts // Salida de tensión continua dependiente de la salida del DAC2: Vdc2 = kv2*V_DAC2;
const float kv1 = Vdc1_max/DAC1_max; // Volts // Salida de tensión continua dependiente de la salida del DAC1: Vdc1 = kv1*V_DAC1;
// Hdc = k*(Vdc1+Vdc2)/R
const float Hdc_absolute_max = -k*Vdc2_min/R; // Oersteds // Valor máximo del campo magnético continuo que puede proporcionar el sistema.
const float Hdc_step_min = k*kv1/R; // Oersteds // Resolución del campo magnético.
const float m = (Vac_max-Vac_punto)/(digipot_max-50); // Pendiente de la ganancia de la amplitud en función del valor del digipot
// Hac = k*Gm*(Vac0+m*digipot_valor), donde Gm es la transconductancia de la carga de salida y digipot_valor es el valor de entrada del digipot en escala de 8 bits.


// SPI conexiones
#define csPin_wavegen 5   // AD9833 CS -> ESP32 GPIO5
#define csPin_digipot 15   // MCP4151 CS -> ESP32 GPIO5
#define sckPin 18  // SPI SCK -> ESP32 GPIO18
#define mosiPin 23  // SPI MOSI -> ESP32 GPIO23

// Indicadores LED
#define ledPin_V 21 // Verde
#define ledPin_A 19 // Azul
#define ledPin_R 17 // Rojo

// Zumbador
#define buzzerPin 16

// DACs
#define dacPin 25   //DAC1
#define dacPin2 26   //DAC2

// ADCs
#define gainPin 4 // Salida detector de ganancia
#define phasePin 2 // Salida detector de fase

// Configuraciones de SPI
SPISettings wavegenSettings(1000000, SPI_MSBFIRST, SPI_MODE2); //En el AD9833 es SPI_MSBFIRST.
SPISettings digipotSettings(1000000, SPI_MSBFIRST, SPI_MODE0);

// Variables globales
int modo = 0; // Modo = 0 --> Conexión por puerto serie (LED verde); Modo = 1 --> Conexión por WiFi (LED rojo); Modo = 2 --> Conexión por Bluetooth (LED azul)
// bool request = true; // request = true --> En reposo (solo se enciende en LED del modo correspondiente); request = false --> Campo magnético activo (barrido de los 3 LEDs en bucle). Al recibir por el puerto serie request=true, envía los parámetros de calibración.
float last_f = 0; // Hz // Para tener constancia a nivel global del valor actual de f y evitar redundancias.
float last_Hdc = 0; // Oersted // Para tener constancia a nivel global del valor actual de Hdc y optimizar procesos.
float last_Hac = 0; // Oersted // Para tener constancia a nivel global del valor actual de Hac y optimizar procesos.
float f_min = 0; // Hz
float f_max = 100000; // Hz
float f_step = 50; // Hz //Originalmente era 50
uint8_t DAC1_valor = 0; // Valor del registro del DAC1
uint8_t DAC2_valor = 0; // Valor del registro del DAC2
uint8_t digipot_valor = 0; // Valor del registro del digipot
float Hdc_min = 0; // Oersted
float Hdc_max = 0; // Oersted
float Hdc_step = 0; // Oersted
float Hac_at_f = 0; // Oersted // Valor del campo deseado a f_at_Hac Hz.
float f_at_Hac = 0; // Hz // Frecuencia a la que se desea la amplitud de campo Hac_at_f.
bool barrido = false; // Indica que hay un barrido en proceso
int samples_per_f = 30; // Cantidad de muestras por cada valor de frecuencia. // Valor recomedado para máxima velocidad: 30. Valor recomendado para mayor equilibrio velocidad/precisión: 50.
int sample_period = 10; // ns
char cmd[10];

// Melodias
struct Note {
    int freq;
    int duration;
};

#define C3  131
#define CS3 139
#define E3  165
#define F3  175
#define FS3 185
#define G3  196
#define GS3 208
#define A3  220
#define AS3 233
#define C4  262
#define CS4 277

Note deviceInitialization[] = {
    {C3, 120},
    {C4, 120},
    {G3, 120},
    {E3, 120},
    {C4, 100},
    {G3, 140},
    {E3, 240},

    {E3, 60},
    {F3, 60},
    {FS3, 60},
    {FS3, 60},
    {G3, 60},
    {GS3, 60},
    {GS3, 60},
    {A3, 60},
    {AS3, 60},
    {C4, 180},
};

Note connected[] = {
    {523, 80},
    {659, 80},
    {784, 80},
    {1047, 150}
};

Note commandError[] = {
    {440, 200},
    {330, 300}
};

Note sweepStart[] = {
    {1200, 40},
    {1350, 40},
    {1500, 40},
    {1800, 80},
    {1600, 50}
};

Note sweepEnd[] = {
    {900, 120},
    {1100, 120},
    {900, 120},
    {1100, 200}
};

// Se define una tarea que será ejecutada en un núcleo diferente al del programa principal, con el fin de ejecutar la animación de luces LED en paralelo al programa principal.
TaskHandle_t Task1;

void initializeWavegen(){
  SPI.beginTransaction(wavegenSettings);
  digitalWrite(csPin_wavegen, LOW);
  SPI.transfer16(0b0010000100000000);//(0b0010000100000000); ///Preparar reg. control, RESET, B28
  SPI.transfer16(0b0100000000000000); // FREQREG LSB
  SPI.transfer16(0b0100000000000000); // FREQREG MSB
  SPI.transfer16(0b1100000000000000); // Reg. fase=0
  SPI.transfer16(0b0010000001000000);//(0b0010000000000000); // Cargar reg. interno, modo reposo
  digitalWrite(csPin_wavegen, HIGH);
  SPI.endTransaction();
  last_f = 0;
}

void setWavegenFrecuency(float f_out){
  if (f_out < 0) f_out = -f_out; // Para corregir la entrada de posibles frecuencias negativas.
  if (f_out != last_f){
    uint32_t FREQREG = f_out * clock_constant; // Valor que debe tener FREQREG para conseguir una salida de frecuencia f_out.
    uint16_t LSB = 0b0100000000000000 | (0b0011111111111111 & FREQREG); //0b00001110100000;
    uint16_t MSB = 0b0100000000000000 | (0b0011111111111111 & (FREQREG>>14)); //0b00000000011011;
    SPI.beginTransaction(wavegenSettings);
    digitalWrite(csPin_wavegen, LOW);
    SPI.transfer16(0b0010000000000000); //Preparar reg. control, RESET, B28, forma de onda sinusoidal
    SPI.transfer16(LSB); // FREQREG LSB
    SPI.transfer16(MSB); // FREQREG MSB
    SPI.transfer16(0b0010000000000000); // Cargar reg. interno, activar salida
    digitalWrite(csPin_wavegen, HIGH);
    SPI.endTransaction();
    last_f = f_out;
  }
}

void setDigipot(uint8_t valor) {
  SPI.beginTransaction(digipotSettings);
  digitalWrite(csPin_digipot, LOW);
  SPI.transfer(0x00); // Dirección del registro del wiper
  SPI.transfer(valor); // Valor del wiper en escala de 0-255
  digitalWrite(csPin_digipot, HIGH);
  SPI.endTransaction();
}

void setDACsFromHdc(float Hdc){
  if (Hdc != last_Hdc){
    float Vdc = -(Hdc*R/k)-Voffset;
    if (Vdc<0){
      DAC2_valor = (int)(Vdc/kv2)+1;
      DAC1_valor = (int)(-(DAC2_valor*kv2-Vdc)/kv1);
    }
    else if (Vdc>0){
      DAC2_valor = 0;
      DAC1_valor = (int)(Vdc/kv1);
    }
    else{
      DAC2_valor = 0;
      DAC1_valor = 0;
    }
    dacWrite(dacPin, DAC1_valor);
    dacWrite(dacPin2, DAC2_valor);
    last_Hdc = Hdc;
    // float Vdc2 = DAC2_valor*kv2;
    // float Vdc1 = DAC1_valor*kv1;
    // float Hdc_conseguido = -(Vdc1+Vdc2)*k/R;
    // Serial.printf("Vdc=%f  DAC2_valor=%d  DAC1_valor=%d  Vdc2=%f Vdc1=%f Hdc_conseguido=%f\n",Vdc,DAC2_valor,DAC1_valor,Vdc2,Vdc1,Hdc_conseguido);
  }
}

bool setDigipotFromHac(float Hac, float f){
  if (Hac != last_Hac){
    float Gm = 1/sqrt(pow(R,2)+pow(2*PI*f*L,2));
    float digipot_valor_float = (Hac/(k*Gm)-Vac0)/m;
    digipot_valor = (int)digipot_valor_float;
    if (digipot_valor_float>=0 && digipot_valor_float<256){
      setDigipot(digipot_valor);
      last_Hac = Hac;
      //Serial.printf("Hac=%f f=%f Gm=%f digipot_valor=%d\n",Hac,f,Gm,digipot_valor);
      return true;
    }
    else {Serial.printf("ERROR: Campo H alterno fuera de rango. Rango de valores permitido para %f Hz: |Hac|∈(%f,%f)\n",f,k*Gm*Vac0,k*Gm*Vac_max);playMelody(commandError,sizeof(commandError));return false;}
  }
}

void playMelody(Note *melody, int totalSize) {
    for (int i = 0; i < totalSize/8; i++) {
        tone(buzzerPin, melody[i].freq, melody[i].duration);
        delay(melody[i].duration * 1.3);
    }
}



void setup() {
  Serial.begin(115200);
  delay(10);
  //Dejamos desactivado el canal del digipot:
  pinMode(csPin_digipot, OUTPUT);
  digitalWrite(csPin_digipot, HIGH);
  delay(10); // Quitar si no hace falta.
  //Inicializamos el generador con CS desactivado:
  pinMode(csPin_wavegen, OUTPUT);
  digitalWrite(csPin_wavegen, HIGH);
  delay(10); // Quitar si no hace falta.
  pinMode(ledPin_V, OUTPUT);
  pinMode(ledPin_A, OUTPUT);
  pinMode(ledPin_R, OUTPUT);
  pinMode(buzzerPin, OUTPUT);
  setDACsFromHdc(0);
  setDigipot(0);
  SPI.begin(sckPin, -1, mosiPin, -1);
  delay(10); // Quitar si no hace falta.
  initializeWavegen();
  delay(10);
  analogSetAttenuation((adc_attenuation_t)2); // Limita el rango de entrada del ADC a 2V.
  //create a task that will be executed in the Task1code() function, with priority 1 and executed on core 0
  xTaskCreatePinnedToCore(
                    Task1code,   /* Task function. */
                    "Task1",     /* name of task. */
                    10000,       /* Stack size of task */
                    NULL,        /* parameter of the task */
                    1,           /* priority of the task */
                    &Task1,      /* Task handle to keep track of created task */
                    0);          /* pin task to core 0 */                   
  delay(2000);
  Serial.println("¡Bienvenido a la interfaz de control del detector de resonancia magnetoelástica!"); // Esto permite comprobar de forma visual que la conexión serial se ha efectuado correctamente.
  Serial.println("La estructura de la introducción comandos es la siguiente:");
  Serial.println("cmd f_min f_max f_step Hdc_min Hdc_max Hdc_step Hac_at_f f_at_Hac samples_per_f sample_period");
  playMelody(deviceInitialization,sizeof(deviceInitialization));
}

// Función que controla los indicadores LED. Se ejecuta en el core 0 en paralelo al void loop, el cual se ejecuta en el core 1.
void Task1code( void * pvParameters ){
  bool lastModo = 3; // El modo=3 es un pseudo-modo para indicar que ha habido un barrido o que se están inicializando los LEDs.
  for(;;){ // Bucle for infinito
    delay(10);
    if ((modo==0) && (lastModo!=0)){
      digitalWrite(ledPin_V, HIGH);
      digitalWrite(ledPin_R, LOW);
      digitalWrite(ledPin_A, LOW);
      lastModo = modo;
    }
    else if ((modo==1) && (lastModo!=1)){
      digitalWrite(ledPin_V, LOW);
      digitalWrite(ledPin_R, HIGH);
      digitalWrite(ledPin_A, LOW);
      lastModo = modo;
    }
    else if ((modo==2) && (lastModo!=2)){
      digitalWrite(ledPin_V, LOW);
      digitalWrite(ledPin_R, LOW);
      digitalWrite(ledPin_A, HIGH);
      lastModo = modo;
    }
    else if (barrido){
      playMelody(sweepStart,sizeof(sweepStart));
      while (barrido){
        digitalWrite(ledPin_V, HIGH);
        delay(666);
        digitalWrite(ledPin_V, LOW);
        digitalWrite(ledPin_R, HIGH);
        delay(666);
        digitalWrite(ledPin_R, LOW);
        digitalWrite(ledPin_A, HIGH);
        delay(666);
        digitalWrite(ledPin_A, LOW);
      }
      playMelody(sweepEnd,sizeof(sweepEnd));
      lastModo = 3;
    }
  } 
}

void loop() {
  delay(100);
  if (Serial.available()) {
    String line = Serial.readStringUntil('\n');
    //Serial.println(line);
    line.trim();
    // int request_int;
    sscanf(line.c_str(), "%9s %f %f %f %f %f %f %f %f %d %d", &cmd, &f_min, &f_max, &f_step, &Hdc_min, &Hdc_max, &Hdc_step, &Hac_at_f, &f_at_Hac, &samples_per_f, &sample_period);
    //request = (request_int != 0);

    //Serial.printf("request=%d  f_min=%.1f  f_max=%.1f  f_step=%.1f Hdc_min=%.2f Hdc_max=%.2f Hdc_step=%.2f\n",request,f_min,f_max,f_step,Hdc_min,Hdc_max,Hdc_step);


    if (strcmp(cmd, "params") == 0){
      Serial.printf("CALIB:    Δf=%f Hz    Hdc_max=%f Oe    ΔHdc=%f Oe    R=%f Ω    L=%f H    k=%f    Vac0=%f V    m=%f\n",f_step_min,Hdc_absolute_max,Hdc_step_min,R,L,k,Vac0,m); // Devuelve los parámetros de calibración y derivados.
    }

    // else if (strcmp(cmd, "stop") == 0){
    //   barrido = false;
    // }

    else if (strcmp(cmd, "raw") == 0){
      setWavegenFrecuency(f_min);
      DAC1_valor = (int) f_max;
      DAC2_valor = (int) f_step;
      dacWrite(dacPin, DAC1_valor);
      dacWrite(dacPin2, DAC2_valor);
      setDigipot(Hdc_min);
    }

    else if (strcmp(cmd, "man") == 0){
      setWavegenFrecuency(f_min);
      setDACsFromHdc(f_max);
      setDigipotFromHac(f_step,Hdc_min);
    }

    else if (strcmp(cmd, "help") == 0){
      Serial.println("");
      Serial.println(">> LISTA DE COMANDOS <<");
      Serial.println("");
      Serial.println("* Para conocer la lista de comandos:");
      Serial.println("    --> help");
      Serial.println("");
      Serial.println("* Solicitar parámetros de calibración:");
      Serial.println("    --> params");
      Serial.println("");
      Serial.println("* Control manual mediante valores crudos de registros:");
      Serial.println("    --> raw f DAC1_valor DAC2_valor digipotValor");
      Serial.println("");
      Serial.println("* Control manual mediante valores de salida deseados:");
      Serial.println("    --> man f Hdc Hac_at_f f_at_Hac");
      Serial.println("");
      Serial.println("* Barrido del campo magnético:");
      Serial.println("    --> sweep f_min f_max f_step Hdc_min Hdc_max Hdc_step Hac_at_f f_at_Hac samples_per_f sample_period");
      Serial.println("");
    }

    else if (strcmp(cmd, "sweep") == 0){
      if (f_min>f_max){Serial.printf("ERROR: La frecuencia mínima no puede ser mayor que la máxima, evidentemente.\n");playMelody(commandError,sizeof(commandError));}
      else if (f_step<f_step_min){Serial.printf("ERROR: Resolución de frecuencia fuera de rango. Valor mínimo permitido: %f Hz\n",f_step_min);playMelody(commandError,sizeof(commandError));}
      //else if (f_step>f_max){Serial.printf("ERROR: La resolución de frecuencia supera la frecuencia máxima.\n");playMelody(commandError,sizeof(commandError));}
      else if (Hdc_min>Hdc_max){Serial.printf("ERROR: El campo H continuo mínimo no puede ser mayor que el máximo, evidentemente.\n");playMelody(commandError,sizeof(commandError));}
      else if (Hdc_max>Hdc_absolute_max){Serial.printf("ERROR: Campo H continuo fuera de rango. Valor máximo permitido: %f Oe\n",Hdc_absolute_max);playMelody(commandError,sizeof(commandError));}
      else if (Hdc_step<Hdc_step_min){Serial.printf("ERROR: Resolución del campo H continuo fuera de rango. Valor mínimo permitido: %f Oe\n",Hdc_step_min);playMelody(commandError,sizeof(commandError));}
      //else if (Hdc_step>Hdc_max){Serial.printf("ERROR: La resolución del campo H continuo supera el campo H continuo máximo\n");playMelody(commandError,sizeof(commandError));}
      else if (samples_per_f<=0){Serial.printf("ERROR: El número de muestras debe ser mayor que cero.\n");playMelody(commandError,sizeof(commandError));}
      else if (sample_period<=0){Serial.printf("ERROR: El periodo de muestreo debe ser mayor que cero.\n");playMelody(commandError,sizeof(commandError));}
      else if (setDigipotFromHac(Hac_at_f,f_at_Hac)){
        float f;
        float Hdc = Hdc_min;
        int valorG;
        int valorP;
        float auxG;
        float auxP;
        float max_valor;
        float max_valor_f;
        barrido = true;
        do {       
          setDACsFromHdc(Hdc);
          delay(5000);       
          f = f_min;
          max_valor=0;
          max_valor_f=0;
          do {
            setWavegenFrecuency(f);
            delay(50);
            auxG=0;
            auxP=0;
            for (int i=0; i<samples_per_f; i++){
              delay(sample_period);
              valorG = analogRead(gainPin);//-900;
              valorP = analogRead(phasePin);
              auxG = auxG+valorG;
              auxP = auxP+valorP;
            }
            auxG = auxG/samples_per_f; //Por alguna extraña razón, no funciona imprimiendo directamente el valor.
            auxP = auxP/samples_per_f;
            if (auxP>max_valor){
              max_valor=auxP;
              max_valor_f=f;
            }
            // if (valor<min_valor){
            //   min_valor=valor;
            //   min_valor_freq=freq;
            // }
            Serial.printf("gpDATA: Hdc: %f Oe    Frecuencia: %f Hz    Ganancia: %f    Fase: %f\n",Hdc,f,auxG, auxP);
            f=f+f_step;
          } while (f<(f_max+f_step) && f_step!=0);
          Serial.printf("HdcDATA: Hdc: %f Oe    fr: %f Hz\n",Hdc,max_valor_f);
          Hdc=Hdc+Hdc_step;
        } while (Hdc<(Hdc_max+Hdc_step) && Hdc_step!=0);
        setDACsFromHdc(0);
        setDigipot(0);
        initializeWavegen();
        barrido = false;
      }
      // request = true;
    }
  }
}
