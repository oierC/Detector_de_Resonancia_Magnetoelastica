// Soporte bobina TFG Oier
//
dtp = 32; // diametro externo tubo primario
ltp = 90; // largo tubo primario
//ltp = 100; // largo tubo primario
dts = 17.5; // diametro externo tubo secundario;
gts = 2; // Grosor tubo secundario
thick = 24; // ancho de la pieza soporte
sobra = 5; // cuanto es mayor la pieza soporte del diametro del tubo
monta = 10; // longitud que monta en el soporte el tubo primario
anillo = 5; // anillo exterior de radios
lts = ltp+2*(thick-monta); // largo tubo secundario
sobra_sec = 3; // pared del soporte del secundario.
da =1.3; // diamtero agujero pasa hilos
desfase = 22.5;

//Parametros de tornillos:
dtorn = 5; //Diametro rosca tornillo. Nota: Este no es el diametro real de la rosca, es un agujero de un diametro más grande pensado para luego unirle por dentro un modelo 3D de tuerca de 4mm.
dcab = 8;  //Diametro cabeza tornillo. El diametro real es de 7, pero le damos un pequeño margen
lcab = 3; //Altura cabeza tornillo
ltorn1 = 5.3; //Largo tornillo1. Nota: Le hemos añadido un margen de 0.5mm.
ltorn2 = 12.7; //Largo tornillo2. Nota: Le hemos añadido un margen de 0.2mm.
ltuerca4mm = 3; //Altura de la tuerca de 4mm

//Parametros del conector SMA:
dr = 10.6; //diametro rosca del conector SMA
drmin = 8.8; //diametro de la zona con muesca muesca de la rosca del conector SMA
muesca= dr-drmin; //tamaño de la mordida
lr = 8; //largo rosca

dSMA = 15.5; //Diametro máximo del macho SMA
lSMA = 12; //Largo de la parte metálica del conector que queda en el exterior
dTuerca = 12.5;
lTuerca = 2.3;

dpunt = 5; //Diametro punta de cobre de SMA
lpunt = 7; //Largo punta de cobre de SMA

//Parametros de la extensión:
margenx = 10; //Margen de espacio entre el conector y la pared de la base
margeny = 2; //Margen de espacio entre el conector y los bordes de la extensión
margenz = 2; //Margen de altura entre el suelo y el SMA
//paredy = 2.9; //Grosor de las paredes en ele eje y
//paredx = 2.9; //Grosor de las paredes en ele eje x
pared = 2.9; //Grosor de las paredes. El fabricante del conector SMA indica explicitamente que la pared en la que se sujeta puede tener un groso máximo de 2.9mm
largo = margenx+lr; //Como de larga es la extensión
alto = dSMA+margenz; //Cómo de alta es la extensión

//Tapa cubre conexiones:
sobraTapa = 5; //Sobrante entre final de hueco y final de tapa
gruesoTapa = 1; //Grosor de la tapa
lDientes= lcab; //Como de largo serán los salientes que sujetan la tapa
dtapa = anillo+sobraTapa; //Diametro máximo de la parte cricular de la tapa
wBase=dtp+2*sobra-2*pared; //Anchura de la zona rectangular
hBase=dtp/2+sobra-pared; //Altura de la zona rectangular
dBase=wBase;    //dtp-anillo+sobraTapa; //Diametro de la zona circular.
lPalo=dBase+dcab;
wPalo=dcab;

//Portamuestras
lmmax = 50; //Longitud máxima de las muestras. Suelen ser de unos 30-50mm.
wmmax = 11; //Anchura máxima de las muestras. Suelen ser de unos 5mm.
hmmax = 1.65; //Altura máxima de las muestras. De momento no lo sé, supongamos 1mm.
lm = lmmax+2;
wm = wmmax+2;
hm = hmmax+0.2;
gsuelo = 2; //Grosor del suelo del portamuestras sobre el que se posaran las muestras.
hparedes=hm+2;
sport = 2; //Sobrante axial del portamuestras.
lsuj = 5;//Longitud del saliente de sujección
rsport = 2*gts+2*sobra_sec+1; //Sobrante radial del portamuestras.
gpatas = lsuj+5; //Grosor de las patas del portamuestras.
hpatas = dts/2-gts-gsuelo-hmmax/2; //altura de las patas.
//Largo tapaNeg = ltorn1+lcab+1 = 5.1 + 3 + 1= 10.1mm
//Largo extension = alto = dSMA+margenz = 15.5 + 2 = 17.7
$fn=100;

module m4nut(){
    import("/home/oier/Desktop/Code/3D/STL/working-m4-screws-and-nut-model_files/m4-nut.stl");
}

module tornillo_m4_5mm(){
    import("/home/oier/Desktop/Code/3D/STL/working-m4-screws-and-nut-model_files/m4-5mm-screw.stl");
}
module tornillo_m4_12mm(){
    import("/home/oier/Desktop/Code/3D/STL/working-m4-screws-and-nut-model_files/m4-12mm-screw.stl");
}


module soporte_primario() {
    translate([thick-monta, dtp/2+sobra, dtp/2+sobra]) rotate([0,90,0]) cylinder(h=ltp,d=dtp);
}

module soporte_secundario() {
    difference(){
        
        translate([0, dtp/2+sobra, dtp/2+sobra])
        rotate([0,90,0])
        cylinder(h=lts,d=dts);
        
        translate([-0.1, dtp/2+sobra, dtp/2+sobra])
        rotate([0,90,0])
        cylinder(h=lts+0.2,d=dts-2*gts);
    }
}

module radio(angle) {
    radio_thick = 1.5;
    translate([(thick-monta)/2,dtp/2+sobra, dtp/2+sobra]) 
    rotate([angle,0,0]) 
    cube([thick-monta,radio_thick,dtp-anillo+2], center = true);
}

module radioPorta(angle,radio_thick) {
    //radio_thick = 1.5;
    //translate([(thick-monta)/2,dtp/2+sobra, dtp/2+sobra]) 
    rotate([angle,0,0]) 
    cube([lsuj+sport+0.2,radio_thick,dtp-anillo+2], center = true);
}

module soporte() {
    
    difference() {
        union() {
            difference() {
              cube([thick,dtp+2*sobra,dtp+2*sobra]);
                soporte_primario();
                translate([0, dtp/2+sobra, dtp/2+sobra])
                rotate([0,90,0])
                cylinder(h=ltp,d=dtp-anillo, center=true);   
            }
            radio(0+desfase);
            radio(45+desfase);
            radio(90+desfase);
            radio(90+45+desfase);
            translate([0, dtp/2+sobra, dtp/2+sobra])
            rotate([0,90,0])
            cylinder(h=thick-monta,d=dts+sobra_sec);
        }
        translate([-1,0,0])
        soporte_secundario();
    }
}

module tornillo1(){
    translate([0,0,0])
    cylinder(h=ltorn1,d = dtorn);

    translate([0,0,ltorn1])
    cylinder(h=3,d = dcab);
}

module tornillo1V7mm(){
    translate([0,0,0])
    cylinder(h=ltorn1,d = dtorn);

    translate([0,0,ltorn1])
    cylinder(h=3,d = 7);
}

module tornillo2(){
    translate([0,0,0])
    cylinder(h=ltorn2,d = dtorn);

    translate([0,0,ltorn2])
    cylinder(h=3,d = dcab);
}

module pasacablesV1(){
    translate([-0.5*thick,dtp/2+sobra,sobra-0.25*da]) rotate([0,90,0]) cylinder(h=2*thick,d = da);
    translate([-0.5*thick,dtp/2+sobra,da]) rotate([0,90,0]) cylinder(h=2*thick,d = da);
    translate([-0.5*thick,dtp/2+sobra,dtp/2+sobra-dts/2]) rotate([0,90,0]) cylinder(h=2*thick,d = da);
    }
    
module pasacablesV2(){
    radio_thick = da;
    h= (dtp-dts)/2+da+1;
    h_pos=sobra-da;
    translate([-3,dtp/2+sobra-radio_thick/2,h_pos])
    cube([thick+6,radio_thick,h], center = false);
    }
    
module SMA(){
    union(){
        //Rosca:
        difference(){
            translate([0, 0, lpunt])
            rotate([0,0,0])
            cylinder(h=lr,d=dr);
            
            translate([-dr,dr/2-muesca,-1])
            cube([20,20,20], center = false);
        }
        //Exterior:
        translate([0,0,lr+lpunt])
        cylinder(h=lSMA,d=dSMA);
        
        //Tuerca:
        translate([0,0,lr+lpunt-pared-lTuerca])
        cylinder(h=lTuerca,d=dTuerca);
        
        //Punta:
        translate([0, 0, 0])
        rotate([0,0,0])
        cylinder(h=lpunt,d=dpunt);
        
    }
}

module SMA2(){
    //Este va ha ser para asegurar espacio de cavidad
    union(){
        //Rosca:
        difference(){
            translate([0, 0, lpunt])
            rotate([0,0,0])
            cylinder(h=lr,d=dr);
            
            translate([-dr,dr/2-muesca,-1])
            cube([20,20,20], center = false);
        }
        //Exterior:
        translate([0,0,lr+lpunt])
        cylinder(h=lSMA,d=dSMA);
        
        //Tuerca:
        translate([0,0,lr+lpunt-pared-lTuerca])
        cylinder(h=lTuerca,d=dTuerca);
        
        //Punta:
        translate([0, 0, 0])
        rotate([0,0,0])
        cylinder(h=lpunt,d=dpunt);
        
        //Cavidad:
        esp1_alto = 3*dr/4;
        esp1_ancho = dTuerca+1.5;
        translate([0,0,lpunt+lr-esp1_alto/2-pared])
        cube([esp1_ancho+10,esp1_ancho,esp1_alto], center=true);
        
    }
}

module dualSMA(){
//    margenx = 10; //Margen de espacio entre el conector y la pared de la base
//    margeny = 2; //Margen de espacio entre el conector y los bordes de la extensión
//    margenz = 2; //Margen de altura entre el suelo y el SMA
//    pared = 3; //Grosor de las paredes
    union(){
        rotate([180,90,0])
        translate([-(dSMA/2+margenz),-dSMA/2-margeny,margenx-lr])
        SMA();
        
        rotate([0,-90,0])
        translate([dSMA/2+margenz,dtp+2*sobra-dSMA/2-margeny,margenx-lr])
        SMA();
    }
}

module dualSMA3(){
    union(){
        rotate([180,90,0])
        translate([-(dSMA/2+margenz),-dSMA/2-margeny,margenx-lr])
        union(){
            SMA2();
            
            //Ranura pasacables:
            pasacables_alto = pared;
            pasacables_ancho = da;
            pasacables_largo = 20;
            translate([0,-pasacables_ancho/2,lpunt+lr-pasacables_alto])
            cube([pasacables_largo,pasacables_ancho,pasacables_alto], center=false);
        }
        
        rotate([0,-90,0])
        translate([dSMA/2+margenz,dtp+2*sobra-dSMA/2-margeny,margenx-lr])
        union(){
            SMA2();
            
            //Ranura pasacables:
            pasacables_alto = pared;
            pasacables_ancho = da;
            pasacables_largo = 20;
            translate([-pasacables_largo,-pasacables_ancho/2,lpunt+lr-pasacables_alto])
            cube([pasacables_largo,pasacables_ancho,pasacables_alto], center=false);
        }
    }
}

module extension4(){   
    desfase = 22.5;
    difference() {
        union() {
            difference() {
                translate([-alto,0,0])
                cube([thick+alto,dtp+2*sobra,dtp+2*sobra]);

                soporte_primario();
                
                translate([0, dtp/2+sobra, dtp/2+sobra])
                rotate([0,90,0])
                cylinder(h=ltp,d=dtp-anillo, center=true);
              
                
            }   

            radio(0+desfase);
            radio(45+desfase);
            radio(90+desfase);
            radio(90+45+desfase);
            
            translate([-alto, dtp/2+sobra, dtp/2+sobra])
            rotate([0,90,0])
            cylinder(h=thick-monta+alto,d=dts+sobra_sec);
            
            //Brazo superior:
            ancho_brazo = dtp/2+sobra+pared-dTuerca-2.9;
            alto_brazo = 10;
            translate([-alto/2,dtp/2+sobra,dtp+2*sobra-alto_brazo])
            cube([alto,ancho_brazo,alto_brazo], center=true);
        }
        translate([-alto-1,0,0])
        soporte_secundario();
        
        translate([-alto,0,dtp+2*sobra-largo+1])
        rotate([0,90,0])
        dualSMA3(); 
                    
    }
}

module baseLeft(){
    union(){
        difference() {
            soporte();
            
            translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltorn1+0.1])
            tornillo1();
            
            translate([thick-2*dcab-1,dtp/2+sobra,dtp+2*sobra-ltorn2+0.1])
            tornillo2();
        }
        
        translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltuerca4mm])
            m4nut();
        
            translate([thick-2*dcab-1,dtp/2+sobra,dtp+2*sobra-ltuerca4mm])
            m4nut();
    }
}

module baseRight(){
    difference(){
        union() {
            soporte();
            
            extension4();
        }
        translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltorn1])
        tornillo1();
        
        translate([thick-2*dcab-1,dtp/2+sobra,dtp+2*sobra-ltorn2])
        tornillo2();
        
        pasacablesV2();
        
        translate([-alto,0,5])
        pasacablesV2();
    }
}

module tapaDientesCirc(){
    difference(){
        //Seción circular:
        union(){
            difference(){
                din = dts+sobra_sec;
                cylinder(h=gruesoTapa+lDientes,d=din+2*gruesoTapa);
                
                translate([0,0,-1])
                cylinder(h=gruesoTapa+lDientes+2,d=din);
            }
            
            difference(){
                dout=dtp-anillo;
                cylinder(h=gruesoTapa+lDientes,d=dout);
                
                translate([0,0,-1])
                cylinder(h=gruesoTapa+lDientes+2,d=dout-2*gruesoTapa);
            }
            
         
        }
        
        //Brazo superior:
        ancho_brazo = 50;//dtp/2+sobra+pared-dTuerca-2.9;
        alto_brazo = 10;
        largo_brazo = 10;
        translate([-(dtp/2+sobra-largo_brazo/2),0,1])
        cube([largo_brazo,ancho_brazo,alto_brazo], center=true);
        
    }
}

module tapaDientesCav(){
    sinpared=10;
    difference(){
        //Cavidades:
        esp1_alto = 3*dr/4;
        esp1_ancho = dTuerca+1.5;
        rotate([0,-90,0])
        
        union(){
            translate([0,dtp/2+sobra-pared-esp1_ancho,dtp/2+sobra-pared-esp1_alto])
            difference(){
                cube([gruesoTapa+lDientes,esp1_ancho,esp1_alto], center=false);
                
                translate([-1,gruesoTapa,gruesoTapa])
                cube([gruesoTapa+lDientes+2,esp1_ancho-2*gruesoTapa,esp1_alto-2*gruesoTapa+sinpared]);
            }
            
            translate([0,-(dtp/2+sobra-pared),dtp/2+sobra-pared-esp1_alto])
            difference(){
                cube([gruesoTapa+lDientes,esp1_ancho,esp1_alto], center=false);   
                
                translate([-1,gruesoTapa,gruesoTapa])
                cube([gruesoTapa+lDientes+2,esp1_ancho-2*gruesoTapa,esp1_alto-2*gruesoTapa+sinpared]);
            }
            
        }
        
        
        //Seción circular:
        dout=dtp-anillo;
        translate([0,0,-1]);
        cylinder(h=gruesoTapa+lDientes+2,d=1);
    }
    
}

module tapaBase(){
    difference(){
        union(){
            cylinder(h=gruesoTapa,d=wBase);
            
            translate([-wBase/2,-hBase,0])
            cube([hBase,wBase,gruesoTapa],center=false);
        }
        
        ancho_brazoNeg = dtp/2+sobra+pared-dTuerca-pared;
        alto_brazoNeg = dtp/2+sobra-pared-(dtp/2-anillo);
        translate([-(dtp/2+sobra-pared+1),-ancho_brazoNeg/2,-1])
        cube([alto_brazoNeg+1,ancho_brazoNeg,lcab+1], center=false);
    }
}

module tapaTornillos(){
    union(){
        //Brazo superior:
        ancho_brazo = dtp/2+sobra+pared-dTuerca-pared;
        alto_brazo = dtp/2+sobra-pared-(dtp/2-anillo)+gruesoTapa;
        ancho_brazoNeg = dtp/2+sobra+pared-dTuerca-pared;
        alto_brazoNeg = dtp/2+sobra-pared-(dtp/2-anillo);
        difference(){
            translate([-(dtp/2+sobra-pared),-ancho_brazo/2,0])
            cube([alto_brazo,ancho_brazo,gruesoTapa+lcab], center=false);
            
            
            translate([-(dtp/2+sobra-pared+1),-ancho_brazoNeg/2,-1])
            cube([alto_brazoNeg+1,ancho_brazoNeg,lcab+1], center=false);
            
            translate([-(dtp/2+sobra-pared-alto_brazoNeg/2),0,0])
            rotate([0,0,0])
            tornillo1();
            
            
        }
        
        //Brazos cruzados:
        difference(){
                union(){
                    rotate([0,0,45])
                    translate([0,0,(gruesoTapa+lcab)/2])
                    cube([lPalo,wPalo,gruesoTapa+lcab], center=true);
                    
                    rotate([0,0,-45])
                    translate([0,0,(gruesoTapa+lcab)/2])
                    cube([lPalo,wPalo,gruesoTapa+lcab], center=true);
                    
                    rotate([0,0,45])
                    translate([lPalo/2,0,0])
                    cylinder(h=gruesoTapa+lcab,d=wPalo);

                    
                    rotate([0,0,-45])
                    translate([lPalo/2,0,0])
                    cylinder(h=gruesoTapa+lcab,d=wPalo);
                }
                dout=dtp-anillo;
                translate([0,0,-1]);
                cylinder(h=gruesoTapa+lDientes+2,d=dout);
                
                translate([-wBase/2-1,-hBase-1,-1])
                cube([hBase+2,wBase+2,gruesoTapa+lcab+2],center=false);
                
                rotate([0,0,45])
                translate([lPalo/2,0,lcab/2-0.5])
                cube([wPalo+2,wPalo+2,lcab+1],center=true);
                //cylinder(h=gruesoTapa+1,d=wPalo);
                
                rotate([0,0,-45])
                translate([lPalo/2,0,lcab/2-0.5])
                cube([wPalo+2,wPalo+2,lcab+1],center=true);
                //cylinder(h=gruesoTapa+1,d=wPalo);
                
                rotate([0,180,135])
                translate([lPalo/2,0,-(ltorn1+lcab)+1])
                tornillo1();
                
                rotate([0,180,-135])
                translate([lPalo/2,0,-(ltorn1+lcab)+1])
                tornillo1();
                
        
            }
    }
}

module tapa(){
    difference(){
        union(){
            tapaDientesCirc();
            
            tapaDientesCav();
            
            tapaBase();
            
            tapaTornillos(); 
         
            
        }
        translate([0,0,-10])
        cylinder(h=lts,d=dts+anillo-2*gruesoTapa);
        
//        dout=dtp-anillo;
//        translate([0,0,-1]);
//        cylinder(h=gruesoTapa+lDientes+2,d=dout);
    }

    
}


module tapaBaseNeg(){
    translate([0,0,-0.1])
        union(){
            cylinder(h=gruesoTapa+0.1,d=wBase);
            
            translate([-wBase/2,-hBase,0])
            cube([hBase,wBase,gruesoTapa+0.1],center=false);
        }             
}


module tapaTornillosNeg(){
    mejorquesobre=10;
    ancho_brazo = dtp/2+sobra+pared-dTuerca-pared+5;
    alto_brazo = dtp/2+sobra-pared-(dtp/2-anillo)+gruesoTapa;
    ancho_brazoNeg = dtp/2+sobra+pared-dTuerca-pared;
    alto_brazoNeg = dtp/2+sobra-pared-(dtp/2-anillo);
    union(){        
        //Tornillo brazo superior:
        translate([-(dtp/2+sobra-pared-alto_brazoNeg/2),0,ltorn1+lcab])
        rotate([180,0,0])
        tornillo1V7mm();
        
        translate([-(dtp/2+sobra-pared),-ancho_brazo/2,-0.1])
        cube([alto_brazo+mejorquesobre,ancho_brazo,gruesoTapa+lcab+0.1], center=false);
        
        //Tornillo brazos cruzados:
        rotate([0,180,135])
        translate([lPalo/2,0,-(ltorn1+lcab)])
        tornillo1();
        
        rotate([0,180,-135])
        translate([lPalo/2,0,-(ltorn1+lcab)])
        tornillo1();
        difference(){
            union(){
                rotate([0,0,45])
                translate([0,0,(gruesoTapa+lcab)/2-0.1/2])
                cube([lPalo,wPalo,gruesoTapa+lcab+0.1], center=true);
                
                rotate([0,0,-45])
                translate([0,0,(gruesoTapa+lcab)/2-0.1/2])
                cube([lPalo,wPalo,gruesoTapa+lcab+0.1], center=true);
            }
            
            translate([-wBase/2-1,-hBase-1,-3])
            cube([hBase+2,wBase+2,gruesoTapa+lcab+4],center=false);
        }
        
        rotate([0,0,45])
        translate([lPalo/2,0,-0.1])
        cylinder(h=gruesoTapa+lcab+0.1,d=wPalo);

        
        rotate([0,0,-45])
        translate([lPalo/2,0,-0.1])
        cylinder(h=gruesoTapa+lcab+0.1,d=wPalo);
        
    }
}

module tapaNeg(){
    //Le he añadido un 0.1 milimetro de margen en el eje axial en la dirección opuesta al solenoide  direccion para que al quitar se vean bien los agujero y no dibuje esa especie de malla.


    difference(){
        union(){           
            tapaBaseNeg();
            
            tapaTornillosNeg();
            
        }
        
        //Hueco del medio    
        translate([0,0,-10])
        cylinder(h=lts,d=dts+anillo-2*gruesoTapa);
    }

    
}

module baseRightV3(){
    
    difference(){
        baseRight();
        
        rotate([0,90,0])
        translate([-(dtp/2+sobra),dtp/2+sobra,-alto+1])
        tapaNeg();
    }

}

module tapaTuercas(){
    ancho_brazo = dtp/2+sobra+pared-dTuerca-pared;
    alto_brazo = dtp/2+sobra-pared-(dtp/2-anillo)+gruesoTapa;
    ancho_brazoNeg = dtp/2+sobra+pared-dTuerca-pared;
    alto_brazoNeg = dtp/2+sobra-pared-(dtp/2-anillo);
    rotate([0,90,0])
    translate([-(dtp/2+sobra),dtp/2+sobra,-alto+1])
    union(){
    
        translate([-(dtp/2+sobra-pared-alto_brazoNeg/2),0,(ltorn1+lcab)-1-0.3])
        rotate([0,180,0])
        m4nut();

        rotate([0,180,135])
        translate([lPalo/2,0,-(ltorn1+lcab)+1+0.3])
        m4nut();

        rotate([0,180,-135])
        translate([lPalo/2,0,-(ltorn1+lcab)+1+0.3])
        m4nut();
    }
    
}

module baseRightV4(){
    union(){
        tapaTuercas();
        difference(){
            union() {
                soporte();
                
                extension4();
            }
            translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltorn1+0.1])
            tornillo1();
            //m4_5mm_screw();
            
            
//            translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltorn1])
//            cylinder(h=7,d=5);
            
            translate([thick-2*dcab-1,dtp/2+sobra,dtp+2*sobra-ltorn2+0.1])
            tornillo2();
            
            pasacablesV2();
            
            translate([-alto,0,5])
            pasacablesV2();
                    
            rotate([0,90,0])
            translate([-(dtp/2+sobra),dtp/2+sobra,-alto])
            tapaNeg();
            
            //Esto es para seccionar la pieza 
//            translate([-(alto+1),-1,-1])
//            cube([100,100,dtp/2+2*sobra+1]);
        }
        
        translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltuerca4mm])
        m4nut();
        
        translate([thick-2*dcab-1,dtp/2+sobra,dtp+2*sobra-ltuerca4mm])
        m4nut();
    }
}
module sujetador(){
    difference(){
        cylinder(h=lsuj+sport,d=dts-2*gts+rsport);
        
        translate([0,0,-0.1])
        cylinder(h=lsuj+0.1,d=dts+sobra_sec+1);
        
        translate([-dtp/2,-dtp/2,-0.1])
        cube([dtp/2,dtp,lsuj+sport+0.2]);
        
        translate([0,0,3.5])
        rotate([0,90,0]){
            radioPorta(0+desfase,1.6);
            radioPorta(10+desfase,3.5);
            radioPorta(15+desfase,1.5);
            radioPorta(20+desfase,1.5);
            radioPorta(45+desfase,10); 
            radioPorta(90+desfase,10);
            radioPorta(-10-desfase,3.5);
            radioPorta(-15-desfase,1.5);
            radioPorta(-20-desfase,1.5);
            radioPorta(90+45+desfase,1.6);
        }
    }
}
module adaptamuestraNeg(){
    sobraGancho=5+0.2;
    anchoGancho=3+0.2;
    ddiente=anchoGancho;
    hdiente=hparedes+2;
    union(){
        cube([lm,wm,hparedes], center = false);
        
        translate([-sobraGancho,wm/2-anchoGancho/2,0])
        cube([lm+2*sobraGancho,anchoGancho,hparedes]);
        
        translate([lm+sobraGancho,wm/2,(hparedes-hdiente)])
        cylinder(h=hdiente,d=ddiente);
        
        translate([-sobraGancho,wm/2,(hparedes-hdiente)])
        cylinder(h=hdiente,d=ddiente);
        
    }
}

module referencia(){
    hmarcaGrande=4;
    hmarca=2;
    gmarca=0.5;
    fmarca=2;
    suelo=1;
    
    //Medio:
    translate([lts/2-gmarca/2,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarcaGrande-hm/2-suelo])
    cube([gmarca,fmarca,hmarcaGrande],center=false);
    
    
    translate([lts/2-gmarca/2-hmarca/2+gmarca/2,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    rotate([0,90,0])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarcaGrande-hm/2-suelo])
    cube([gmarca,fmarca,hmarcaGrande],center=false);
    
    translate([lts/2-gmarca/2-hmarca/2+gmarca/2,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    rotate([0,90,0])
    cube([gmarca,fmarca,hmarca],center=false);
    
    
    //5mm:
    translate([lts/2-gmarca/2-5,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2-5,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+5,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+5,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    //10mm:
    translate([lts/2-gmarca/2-10,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2-10,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+10,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+10,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    //15mm:
    translate([lts/2-gmarca/2-15,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2-15,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+15,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+15,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    //20mm:
    translate([lts/2-gmarca/2-20,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2-20,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+20,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+20,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    //25mm:
    translate([lts/2-gmarca/2-25,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2-25,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+25,dtp/2+sobra-dts/2+gts,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
    translate([lts/2-gmarca/2+25,dtp/2+sobra+dts/2-gts-fmarca,sobra+dtp/2-hmarca-hm/2-suelo])
    cube([gmarca,fmarca,hmarca],center=false);
    
}

module portamuestras(){
    union(){
        difference(){
            translate([0, dtp/2+sobra, dtp/2+sobra])
            rotate([0,90,0])
            cylinder(h=lts+sport,d=dts-2*gts-0.5);
            
            translate([-0.1,dtp/2+sobra-dts/2, dtp/2+sobra+hparedes-hm])
            cube([lts+sport+0.2,dts,dts/2], center = false);
            
            translate([(lts-lm)/2,dtp/2+sobra-wm/2, dtp/2+sobra-hm/2])
            adaptamuestraNeg();
            
//            translate([gpatas,dtp/2+sobra-dts/2, dtp/2+sobra-dts/2+gts])
//            cube([lts-2*gpatas,dts,hpatas], center = false);
            referencia();
        }
    translate([lts-lsuj, dtp/2+sobra, dtp/2+sobra])
    rotate([0,90,0])
    sujetador();
    }
}

module montado(){
    union(){
        color("black")
        baseRightV4();
        
        color("lightgray")
        translate([-alto,0,dtp+2*sobra-largo+1])
        rotate([0,90,0])
        dualSMA();
        
        color("white")
        translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltorn1])
        tornillo_m4_5mm();
        
        color("white")
        translate([thick-2*dcab-1,dtp/2+sobra,dtp+2*sobra-ltorn2])
        tornillo_m4_12mm();
        
        color("gray")
        translate([0,0,0])
        soporte_primario();
        
        color("lightblue")
        soporte_secundario();
        
        rotate([180,180,0])
        translate([-(ltp+2*(thick-monta)),-(dtp+2*sobra),0])
        union(){
            color("black")
            baseLeft();
            
            color("white")
            translate([thick-dcab+1,dtp/2+sobra,dtp+2*sobra-ltorn1])
            tornillo_m4_5mm();
            
            color("white")
            translate([thick-2*dcab-1,dtp/2+sobra,dtp+2*sobra-ltorn2])
            tornillo_m4_12mm();
            
            
        }
        rotate([0,90,0])
        translate([-(dtp/2+sobra),dtp/2+sobra,-alto])
        tapa();
        
        color("white")
        rotate([0,-90,0])
        translate([dcab/2+1,dcab/2+1,alto-ltorn1-lcab])
        tornillo_m4_5mm();
        
        color("white")
        rotate([0,-90,0])
        translate([dcab/2+1,dtp+2*sobra-dcab/2-1,alto-ltorn1-lcab])
        tornillo_m4_5mm();
        
        color("white")
        rotate([0,-90,0])
        translate([dtp+2*sobra-pared-dcab/2,dtp/2+sobra,alto-ltorn1-lcab])
        tornillo_m4_5mm();
        
        color("red")
        portamuestras();
        
        
    }
}
//color("black")
//rotate([180,180,0])
//baseRightV4();
//color("blue")
//baseLeft();
//tapa();
montado();
//tapaTuercas();

//union(){
//    soporte_secundario();
//    color("red")
//    portamuestras();
//}
//portamuestras();
//adaptamuestraNeg();


