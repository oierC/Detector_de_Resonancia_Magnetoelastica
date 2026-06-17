### *V10: Al tocar el botón de iniciar o al iniciar el barrido en frecuencia para un campo H continuo diferente se borran los datos de la gráfica amplitud/fase.
### *V10: Cuando el microcontrolador reporta un error la etiqueta de notificaciones cambia a color rojo y el texto describe los errores.
import tkinter as tk
from tkinter import font, ttk
import serial
import serial.tools.list_ports
import time
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import re
import csv
from matplotlib.ticker import AutoMinorLocator
from tkinter import filedialog


# --- VARIABLES GLOBALES ---
Hdc_values = []
frecuencia_values = []
amplitud_values = []
fase_values = []
all_frecuencia_values = []
all_amplitud_values = []
all_fase_values = []
Hdc2_values = []
fr_values = []

error_description = ""

# --- PARÁMETROS DE CALIBRACIÓN
f_step_min = 0
Hdc_absolute_max = 0
Hdc_step_min = 0
R = 0
L = 0
k = 0
Vac0 = 0
m = 0

ser = None
linea = ""


# ---------------- FILTRO VID/PID ----------------
VIDS_VALIDOS = [
    0x10C4,  # CP210x (muy común en ESP32)
    0x1A86,  # CH340
    0x0403,  # FTDI
    0x2341   # Arduino
]


def obtener_puertos():
    puertos = serial.tools.list_ports.comports()

    lista = []

    for p in puertos:
        if p.vid in VIDS_VALIDOS:
            lista.append(f"{p.device} - {p.description}")

    return lista


def actualizar_lista_puertos():
    puertos = obtener_puertos()
    combo_puertos["values"] = puertos

    if puertos:
        combo_puertos.current(0)
    else:
        puerto_var.set("Sin puertos compatibles")


def conectar_puerto():
    global ser

    if not puerto_var.get():
        print("No hay puerto seleccionado")
        return

    puerto = puerto_var.get().split(" - ")[0]

    try:
        if ser and ser.is_open:
            ser.close()

        ser = serial.Serial(puerto, 115200, timeout=1)
        time.sleep(2)
        notificar_parametros(f"Conectado a {puerto}")

    except Exception as e:
        ser = None
        notificar_error(f"Error al conectar: {e}")


# ---------------- FUNCIONES SERIAL ----------------

def update_serial_output(comando):
    if ser and ser.is_open:
        ser.write(comando.encode())
        notificar_parametros(f"Comando enviado: {comando}")
        print()
    else:
        notificar_error("Puerto no conectado")

def iniciarBarrido():
    etiqueta_notif.config(text="")
    root.focus_set()

    if not mantener_valores.get():
        del amplitud_values[:]
        del frecuencia_values[:]
        del fase_values[:]
        del all_amplitud_values[:]
        del all_frecuencia_values[:]
        del all_fase_values[:]
        del Hdc2_values[:]
        del fr_values[:]
        actualizar_pgVSf()
        actualizar_frVSHdc()

    f_min = cajetilla_f_min.get().strip()
    if not f_constante.get():
        f_max = cajetilla_f_max.get().strip()
        f_step = cajetilla_f_step.get().strip()
    else:
        f_max = f_min
        f_step = 1
    Hdc_min = cajetilla_Hdc_min.get().strip()
    if not Hdc_constante.get():
        Hdc_max = cajetilla_Hdc_max.get().strip()
        Hdc_step = cajetilla_Hdc_step.get().strip()
    else:
        Hdc_max = Hdc_min
        Hdc_step = 1
    Hac = cajetilla_Hac.get().strip()
    Hac_f = cajetilla_Hac_f.get().strip()
    muestras_f = int(cajetilla_muestras_f.get().strip())
    periodo_mues = int(cajetilla_periodo_mues.get().strip())
    
    comando = f"sweep {f_min} {f_max} {f_step} {Hdc_min} {Hdc_max} {Hdc_step} {Hac} {Hac_f} {muestras_f} {periodo_mues}"
    update_serial_output(comando)

def etiqueta_con_subindice(parent, texto, subtexto, unidades, x, y):
    
    tk.Label(
        parent,
        text=texto,
        font=("Arial", 12,"bold")
    ).place(x=x, y=y)

    tk.Label(
        parent,
        text=subtexto,
        font=("Arial", 7,"bold")
    ).place(x=x+6+len(texto)*12, y=y+12)

    tk.Label(
        parent,
        text="["+unidades+"]:",
        font=("Arial", 12,"bold")
    ).place(x=x+6+12*len(texto)+8*len(subtexto)+10, y=y)

def notificar_error(texto):
    etiqueta_notif.config(text=texto,fg="red")

def notificar_parametros(texto):
    etiqueta_notif.config(text=texto,fg="blue")

def consulta_calib():
    update_serial_output("params")

def actualizar_pgVSf():
    ax1.cla()
    # ax1.scatter(frecuencia_values, amplitud_values, color='blue')
    ax1.plot(frecuencia_values, amplitud_values, '-o', color='blue')
    ax1.set_title("V_mag [mV] VS f [Hz]")
    ax2.cla()
    # ax2.scatter(frecuencia_values, fase_values, color='red')
    ax2.plot(frecuencia_values, fase_values, '-o', color='red')
    ax2.set_title("V_phs [mV] VS f [Hz]")
    ax1.minorticks_on()  # activa subdivisiones
    ax1.grid(which='minor', linestyle=':', linewidth=0.5)  # líneas finas
    ax1.grid(which='major', linestyle=':', linewidth=1)
    ax2.minorticks_on()  # activa subdivisiones
    ax2.grid(which='minor', linestyle=':', linewidth=0.5)  # líneas finas
    ax2.grid(which='major', linestyle=':', linewidth=1)
    canvas1.draw()

def actualizar_frVSHdc():
    ax3.cla()
    # ax3.scatter(frecuencia_values, fase_values, color='green')
    ax3.plot(Hdc2_values, fr_values, '-o', color='green')
    ax3.set_title("f_r [Hz] VS H_DC [Oe]")
    ax3.minorticks_on()  # activa subdivisiones
    ax3.grid(which='minor', linestyle=':', linewidth=0.5)  # líneas finas
    ax3.grid(which='major', linestyle=':', linewidth=1)
    canvas2.draw()

def guardar_pgVSf():   
    ruta = filedialog.asksaveasfilename(
        title="Guardar datos",
        defaultextension=".csv",
        filetypes=[
            ("Archivos CSV", "*.csv"),
            ("Archivos de texto", "*.txt"),
            ("Todos los archivos", "*.*")
        ]
    )

    # El usuario pulsó Cancelar
    if not ruta:
        return

    columnas = [Hdc_values,all_frecuencia_values,all_amplitud_values,all_fase_values]

    try:
        with open(ruta, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)

            # Cabecera opcional
            writer.writerow(["Hdc","Frecuencia", "Amplitud", "Desfase"])

            # Datos
            writer.writerows(zip(*columnas))

        print(f"Datos guardados en: {ruta}")

    except Exception as e:
        print(f"Error al guardar: {e}")

def guardar_frVSHdc():   
    ruta = filedialog.asksaveasfilename(
        title="Guardar datos",
        defaultextension=".csv",
        filetypes=[
            ("Archivos CSV", "*.csv"),
            ("Archivos de texto", "*.txt"),
            ("Todos los archivos", "*.*")
        ]
    )

    # El usuario pulsó Cancelar
    if not ruta:
        return

    columnas = [Hdc2_values,fr_values]

    try:
        with open(ruta, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)

            # Cabecera opcional
            writer.writerow(["Hdc", "Frecuencia de resonancia"])

            # Datos
            writer.writerows(zip(*columnas))

        print(f"Datos guardados en: {ruta}")

    except Exception as e:
        print(f"Error al guardar: {e}")


def ocultar_f():
    if f_constante.get():
        etiqueta_f_min.place_forget()
        etiqueta_f_max.place_forget()
        cajetilla_f_max.place_forget()
        etiqueta_f_step.place_forget()
        cajetilla_f_step.place_forget()
    else:
        etiqueta_f_min.place(x=x1, y=y1)
        etiqueta_f_max.place(x=x3, y=y1)
        cajetilla_f_max.place(x=x4, y=y1)
        etiqueta_f_step.place(x=x5, y=y1)
        cajetilla_f_step.place(x=x6, y=y1)

def ocultar_Hdc():
    if Hdc_constante.get():
        etiqueta_Hdc_min.place_forget()
        etiqueta_Hdc_max.place_forget()
        cajetilla_Hdc_max.place_forget()
        etiqueta_Hdc_step.place_forget()
        cajetilla_Hdc_step.place_forget()
    else:
        etiqueta_Hdc_min.place(x=x1, y=y2)
        etiqueta_Hdc_max.place(x=x3, y=y2)
        cajetilla_Hdc_max.place(x=x4, y=y2)
        etiqueta_Hdc_step.place(x=x5, y=y2)
        cajetilla_Hdc_step.place(x=x6, y=y2)

# def ocultar_Hdc():
#     etiqueta_Hdc_min.forget()
#     etiqueta_Hdc_max.forget()
#     cajetilla_Hdc_max.forget()

# def update_serial_input(linea):
#     label1.config(text="Lectura puerto serie:")
#     label2.config(text=linea)


def actualizar():
    global linea, muestras_counter

    try:
        if ser and ser.is_open and ser.in_waiting:

            linea = ser.readline().decode(errors="ignore").strip()
            print(linea)

            calib = re.match(
                r"CALIB:\s*Δf=\s*([-+]?[0-9.]+)\s*Hz\s*"
                r"Hdc_max=\s*([-+]?[0-9.]+)\s*Oe\s*"
                r"ΔHdc=\s*([-+]?[0-9.]+)\s*Oe\s*"
                r"R=\s*([-+]?[0-9.]+)\s*Ω\s*"
                r"L=\s*([-+]?[0-9.]+)\s*H\s*"
                r"k=\s*([-+]?[0-9.]+)\s*"
                r"Vac0=\s*([-+]?[0-9.]+)\s*V\s*"
                r"m=\s*([-+]?[0-9.]+)",
                linea
            )

            gpDATA = re.match(
                r"gpDATA:\s*Hdc:\s*([-+]?[0-9.]+)\s*Oe\s*"
                r"Frecuencia:\s*([-+]?[0-9.]+)\s*Hz\s*"
                r"Ganancia:\s*([-+]?[0-9.]+)\s*"
                r"Fase:\s*([-+]?[0-9.]+)",
                linea
            )

            #"HdcDATA: Hdc: %f Oe    fr: %f Hz\n",Hdc,max_valor_f
            HdcDATA = re.match(
                r"HdcDATA:\s*Hdc:\s*([-+]?[0-9.]+)\s*Oe\s*"
                r"fr:\s*([-+]?[0-9.]+)\s*Hz",
                linea
            )

            if calib:
                # f_step_min = float(calib.group(1))
                # Hdc_absolute_max = float(calib.group(2))
                # Hdc_step_min = float(calib.group(3))
                # R = float(calib.group(4))
                # L = float(calib.group(5))
                # k = float(calib.group(6))
                # Vac0 = float(calib.group(7))
                # m = float(calib.group(8))
                param_description = linea.split("CALIB:", 1)[1].strip()
                notificar_parametros(param_description)

            elif linea.startswith("ERROR"):
                error_description = linea.split("ERROR:", 1)[1].strip()
                notificar_error(error_description)
            
            elif HdcDATA:
                Hdc2_values.append(float(HdcDATA.group(1)))
                fr_values.append(float(HdcDATA.group(2)))
                if not mantener_valores.get():
                    del amplitud_values[:]
                    del frecuencia_values[:]
                    del fase_values[:]
                    actualizar_frVSHdc()

            elif gpDATA:
                # update_serial_input(linea)
                Hdc = float(gpDATA.group(1))
                f = float(gpDATA.group(2))
                G = float(gpDATA.group(3))
                P = float(gpDATA.group(4))
                Hdc_values.append(Hdc)
                frecuencia_values.append(f)
                amplitud_values.append(G)
                fase_values.append(P)
                all_frecuencia_values.append(f)
                all_amplitud_values.append(G)
                all_fase_values.append(P)
                actualizar_pgVSf()
                
    except Exception as e:
        print(f"Error: {e}")

    finally:
        root.after(50, actualizar)


# ---------------- GUI ----------------

root = tk.Tk()
root.title("Detector resonancia magnetoelástica V10")
root.geometry(f"{root.winfo_screenwidth()}x{root.winfo_screenheight()}+0+0")

fuente_titulos = font.Font(family="Arial", size=16, weight="bold")
fuente_valores = font.Font(family="Arial", size=14)


# -------- PUERTOS --------
puerto_var = tk.StringVar()
y0 = 10
x0 = 10
x_correc = 1130
tk.Label(root, text="Puerto serie:", font=("Arial", 12, "bold")).place(x=x0+x_correc, y=y0)

combo_puertos = ttk.Combobox(root, textvariable=puerto_var, state="readonly", width=35)
combo_puertos.place(x=150+x_correc, y=12)

tk.Button(root, text="Actualizar", command=actualizar_lista_puertos).place(x=420+100+x_correc, y=8)
tk.Button(root, text="Conectar", command=conectar_puerto).place(x=520+100+x_correc, y=8)

actualizar_lista_puertos()


# -------- SERIAL OUTPUT --------
# label1 = tk.Label(root, text="Lectura de puerto serie:", font=fuente_titulos)
# label1.place(x=0, y=60)

# label2 = tk.Label(root, text=linea, font=fuente_valores)
# label2.place(x=10, y=100)

# tk.Label(root, text="Escritura:", font=fuente_titulos).place(x=0, y=140)

# cajetilla_escritura = tk.Entry(root, width=60, font=("Arial", 14))
# cajetilla_escritura.place(x=10, y=180)

# tk.Button(root, text="Enviar", command=update_serial_output).place(x=10, y=220)


# -------- INTRODUCCIÓN DE PARÁMETROS --------

y1 = 20+1*40
y2 = 20+2*40
y3 = 20+3*40
y4 = 20+4*40
y5 = 20+5*40
x1 = 10+1*200+0*50+2
x2 = 10+1*200+1*50+40
x3 = 10+2*200+1*50-20
x4 = 10+2*200+2*50+30-20
x5 = 10+3*200+2*50-6-45
x6 = 10+3*200+3*50-40
x7 = x6 +110
x8 = x0 +1000
x9 = x1 +1000
x10 = x2 +1000+5
x11 = x3 +1000
x13 = x6+1000-5

# -------- MODO DE OPERACIÓN --------
tk.Label(root, text="Modo de operación:", font=("Arial", 12, "bold")).place(x=x0, y=y0)
modo = tk.StringVar(value="barrido")
x_corr2=-600
tk.Radiobutton(
    root,
    text="Barrido",
    font=("Arial", 12),
    variable=modo,
    value="barrido"
).place(x=x6+100+x_corr2, y=y0+15,anchor="w")

tk.Radiobutton(
    root,
    text="Manual",
    font=("Arial", 12),
    variable=modo,
    value="manual"
).place(x=x6+210+x_corr2, y=y0+15,anchor="w")

tk.Radiobutton(
    root,
    text="Calibrar",
    font=("Arial", 12),
    variable=modo,
    value="calibrar"
).place(x=x6+210+115+x_corr2, y=y0+15,anchor="w")




# Frecuencia
tk.Label(root, text="Frecuencia  [Hz]:", font=("Arial", 12, "bold")).place(x=x0, y=y1)
etiqueta_f_min = tk.Label(root, text="Mínimo:", font=("Arial", 12))
etiqueta_f_min.place(x=x1, y=y1)
cajetilla_f_min = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_f_min.place(x=x2, y=y1)
etiqueta_f_max = tk.Label(root, text="Máximo:", font=("Arial", 12))
etiqueta_f_max.place(x=x3, y=y1)
cajetilla_f_max = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_f_max.place(x=x4, y=y1)
etiqueta_f_step = tk.Label(root, text="Paso:", font=("Arial", 12))
etiqueta_f_step.place(x=x5, y=y1)
cajetilla_f_step = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_f_step.place(x=x6, y=y1)
f_constante = tk.BooleanVar(value=False)
tk.Checkbutton(root, text='Constante',variable=f_constante, onvalue=1, offvalue=0, command=ocultar_f, font=("Arial", 12)).place(x=x7, y=y1)

# Hdc
etiqueta_con_subindice(root, "Campo H", "DC","Oe", x=x0, y=y2)
etiqueta_Hdc_min = tk.Label(root, text="Mínimo:", font=("Arial", 12))
etiqueta_Hdc_min.place(x=x1, y=y2)
cajetilla_Hdc_min = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_Hdc_min.place(x=x2, y=y2)
etiqueta_Hdc_max = tk.Label(root, text="Máximo:", font=("Arial", 12))
etiqueta_Hdc_max.place(x=x3, y=y2)
cajetilla_Hdc_max = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_Hdc_max.place(x=x4, y=y2)
etiqueta_Hdc_step = tk.Label(root, text="Paso:", font=("Arial", 12))
etiqueta_Hdc_step.place(x=x5, y=y2)
cajetilla_Hdc_step = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_Hdc_step.place(x=x6, y=y2)
Hdc_constante = tk.BooleanVar(value=False)
tk.Checkbutton(root, text='Constante',variable=Hdc_constante, onvalue=1, offvalue=0, command=ocultar_Hdc, font=("Arial", 12)).place(x=x7, y=y2)

# Hac
etiqueta_con_subindice(root, "Campo H", "AC","Oe",x=x8, y=y1)
tk.Label(root, text="Amplitud:", font=("Arial", 12)).place(x=x9, y=y1)
cajetilla_Hac = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_Hac.place(x=x10, y=y1)
cajetilla_Hac.insert(0, "0.2")
tk.Label(root, text="Frecuencia de referencia [Hz]:", font=("Arial", 12)).place(x=x11, y=y1)
cajetilla_Hac_f = tk.Entry(root, width=10, font=("Arial", 12))
cajetilla_Hac_f.place(x=x13, y=y1)
cajetilla_Hac_f.insert(0, "50000")


# Muestreo
tk.Label(root, text="Muestreo:", font=("Arial", 12, "bold")).place(x=x8, y=y2)
tk.Label(root, text="Muestras por frecuencia:", font=("Arial", 12)).place(x=x8+118, y=y2)
cajetilla_muestras_f = tk.Entry(root, width=5, font=("Arial", 12))
cajetilla_muestras_f.place(x=x10+55, y=y2)
cajetilla_muestras_f.insert(0, "50")
tk.Label(root, text="Periodo de muestreo [ms]:", font=("Arial", 12)).place(x=x11, y=y2)
cajetilla_periodo_mues = tk.Entry(root, width=5, font=("Arial", 12))
cajetilla_periodo_mues.place(x=x13-30, y=y2)
cajetilla_periodo_mues.insert(0, "10")

# Botones
tk.Button(root, text="Iniciar barrido", command=iniciarBarrido, font=("Arial", 12)).place(x=x0+20, y=y4)
tk.Button(root, text="Consultar parámetros de calibración", command=consulta_calib, font=("Arial", 12)).place(x=x3+50, y=y4)

mantener_valores = tk.BooleanVar(value=False)
tk.Checkbutton(root, text='Mantener valores del gráfico',variable=mantener_valores, onvalue=1, offvalue=0, font=("Arial", 12)).place(x=x1-20, y=y4)
# Notificaciones
etiqueta_notif = tk.Label(root, text="¡Bienvenido a la interfaz gráfica del detector de resonancia magnetoelástica!", font=("Arial", 12))
etiqueta_notif.place(x=x0, y=y5)


# -------- GRÁFICAS --------
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 10), constrained_layout=True)

ax1.set_title("Amplitud")
ax2.set_title("Fase")

canvas1 = FigureCanvasTkAgg(fig, master=root)
canvas1.get_tk_widget().place(x=50, y=250, width=800, height=700)

fig2, (ax3) = plt.subplots(1, 1, figsize=(8, 10), constrained_layout=True)

ax3.set_title("Hdc VS fr")

canvas2 = FigureCanvasTkAgg(fig2, master=root)
canvas2.get_tk_widget().place(x=1000, y=250, width=800, height=700)

# -------- GUARDAR --------
tk.Button(root, text="Guardar", command=guardar_pgVSf).place(x=400, y=960)
tk.Button(root, text="Guardar", command=guardar_frVSHdc).place(x=1400, y=960)



# -------- LOOP --------
actualizar()
root.mainloop()

if ser:
    ser.close()