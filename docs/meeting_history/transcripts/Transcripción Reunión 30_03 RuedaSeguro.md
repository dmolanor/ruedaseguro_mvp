### **Transcripción de la Reunión (Consolidada y Corregida)**

**F. Angles**: Okay. Esto, esto es importantísimo porque esto es parte del marco legal, ¿okay? O sea, es a juro, no podemos escapar de eso, ¿okay? Pero claro, ¿cuál fue la fórmula más sencilla que lo conseguimos para que no estuvieran escribiendo la gente todo el tiempo eso? Bueno, ya lo direccionamos de esa manera, ¿okay?

**Diego**: Listo. Ya, listo. Y entonces, cuando envían la póliza, ¿en qué formato lo envían a la aseguradora?

**F. Angles**: Un PDF.

**Diego**: Okay. ¿Y tienen algún ejemplo de ese PDF?

**F. Angles**: Sí, claro.

**Fer Molano**: Yo tengo una pregunta al respecto allí. ¿Quién emite la póliza? ¿La emite Rueda Seguro o la emite...?

**Alex**: No, la emite Rueda Seguro, la idea sería emitirla nosotros como Insurtech. Nosotros ¿qué hacemos? Captamos esto, nos pegamos vía API con la compañía de seguro, jalamos la estructura de datos de ellos, o se la completamos, y pedimos de vuelta la póliza. Y nos cae en el sistema. Así funciona ahorita.

**Fer Molano**: Okay.

**F. Angles**: Sí, es más, fíjense, fíjense algo, esa parte... recuerden que aquí en este, en este negocio hay dos cosas, está la póliza de RCV y los servicios adicionales que nosotros vamos a dar, ¿okay? Que son de parte de Rueda Seguro. Esa póliza de ley la tiene que emitir una compañía de seguros, ¿qué es lo que tenemos nosotros? Nosotros tenemos la potestad de la compañía de seguro de que nosotros la emitimos y después le informamos a ellos lo que emitimos, ¿okay? O sea, nosotros vamos emitiendo con un correlativo que tenemos nosotros, vamos emitiendo, emitiendo, y al final del día o a una hora específica, nosotros le decimos: 'mira, emití todas estas pólizas', y ellos lo registran en su sistema, ¿okay? Esa fue la manera como más fácil que conseguimos...

**Alex**: Sin embargo queremos hacerla vía API.

**F. Angles**: Claro, queremos hacerlo vía API para que sea mucho más fluido con ellos, ¿no? Pero hoy lo tenemos, hoy lo tenemos así. Entonces fíjate, ahí de todas maneras te acabo de pasar lo que sale por parte de la póliza, ¿okay? de la póliza de RCV. Esa es una póliza de RCV y el otro es el carnecito que te imprime que es prácticamente un resumen de los datos que tienen en el otro lado.

**Diego**: Listo.

**F. Angles**: Si ves estos, si ves estos archivos que te estoy mandando te das cuenta el porqué te estoy diciendo de los datos que tenemos que recoger, porque bueno, justamente los que están vaciados ahí son esos que te estoy diciendo que hay que recoger de estos dos...

**Diego**: Claro. Okay.

**Thony**: Entonces, digamos que a nivel de la emisión de la póliza se haría a nivel del IoT y se empuja a la aplicación y la aplicación la muestra localmente, ¿correcto? A nivel de flujo de trabajo. O sea, digamos que...

**F. Angles**: Mira, a nivel de flujo de trabajo cómo lo veo yo, yo lo veo lo mismo que te dije, dos bloques. Hay un bloque que vamos a tener que vamos a emitir la póliza de RCV de ley y otro bloque que es nuestros servicios, ¿okay? Ya nosotros, o sea, ya con esto que yo te estoy diciendo son los datos que nosotros necesitamos para emitir la de ley. Ahora los servicios de nosotros, tenemos que ver si vamos a pedir datos adicionales, ¿okay? Dependiendo del servicio que vayamos a dar. O sea, por ejemplo, probablemente necesitemos unos números de aviso de, si tenemos una especie de botón de pánico o algo que le avise a la persona que tuvo un accidente o lo que sea, eso ya es otra cuestión. Estos datos que te estoy diciendo, para la póliza de RCV de ley. Hasta ahora aquí vamos a hacer lo mismo que se hace normalmente. ¿Oíste?

**Thony**: Okay, okay.

**F. Angles**: ¿Qué podemos hacer nosotros? Nosotros hoy en día tenemos un sistema que emite pólizas de RCV. Si es más fácil pegarnos a nuestro sistema para que la emita, que tú lo que hagas es mandarme esos datos y yo te devuelvo vía API el cuadro de póliza, lo hacemos, ¿okay?

**Diego**: Okay.

**Thony**: Okay.

**F. Angles**: Lo que tenemos es que mandarte la estructura de cómo está hecho ese sistema para que la entiendas, para que la veas, pues. ¿Oíste? Yo de hecho en el grupo había pasado como un proyecto de que lo habíamos emitido por OCR de este chamo... correcto. Pero bueno, si quieres seguimos, vamos viendo. ¿Okay?

**Fer Molano**: Pero entonces a la aseguradora, ¿solo se le manda el RCV básico? Cualquier cosa encima...

**F. Angles**: Ah okay. Okay, exacto. A la aseguradora ¿qué le mandamos nosotros? Le mandamos la foto de la cédula, le mandamos la foto del carnet de circulación con el que estamos haciendo OCR, y con esos datos yo le lleno un cuadrito de Excel con unos parámetros que ellos nos dieron porque ellos suben eso de manera manual, o sea, bueno, de manera manual suben esa data de una vez a su sistema, ¿okay? Con unas condiciones, no sé, creo que es nombre, cédula, teléfono, dirección, bla bla bla, todo eso, ¿okay? Yo, por lo menos, hoy lo hacemos así, hacemos un cierre a una hora con esa información y le mandamos a ellos el expediente que es la cédula y el carnet.

**Fer Molano**: Okay. Y cualquier plan, porque eso es el plan de $17, ¿cierto?

**F. Angles**: Fíjate, correcto, exacto. Nosotros ¿qué es lo que va a pasar? Todos los planes van a variar, pero la parte de compañía de seguros no va a variar, ¿okay? Porque en la parte de compañía de seguros solamente vamos a emitir esa responsabilidad civil de ley, ¿okay? Que es la que exige el estado. Los servicios adicionales ya son por parte nuestra, esa información y eso sí lo tenemos que almacenar nosotros. Pero en la compañía de seguros lo único que nos va a emitir es un papel.

**Alex**: Okay. Eh, tenemos por definir si hay una parte del riesgo de salud que lo vamos a ceder o no o lo vamos a cubrir con una cuota de afiliación. Sin embargo te vamos a pasar las dos cosas, porque si es así, el cliente tiene que seleccionar si quiere un plan de 500 dólares, quiere un plan de 1500, quiere un plan de 2000, que es el tema de la cobertura de salud. ¿Okay? De hecho en esta presentación donde lo explica. Porque okay, esto es para emitir toda la cobertura de responsabilidad civil, ahora viene el core de este negocio: ocupante de vehículo. Te das un tortazo, ¿cómo estás cubierto? Entonces esos datos son los que siguen, en los planes que vamos a cargar. Vamos a cargar los planes que son de estabilización de trauma y de AP y vida, son dos coberturas adicionales que se indemniza en caso de que haya el accidente.

**Fer Molano**: Okay, ahí te tengo una pregunta. Este... cuando tú contratas la póliza ¿tú ya indicas quiénes son los ocupantes normalmente de la póliza?

**F. Angles**: No, no lo indicas. Pero en este caso, te lo va a tomar por default, te va a poner el mismo que está emitiendo la póliza. ¿Oíste?

**Fer Molano**: Claro, yo lo pregunté por los acompañantes, porque si tú te das un tortazo y ibas con un amigo... entiendo que la póliza te cubre acompañante. ¿Cómo sabe que...?

**F. Angles**: Sí claro, es que la cobertura de AP ocupantes dentro de las coberturas de los vehículos te cubre y no están nombrados, cubre al que iba encima del carro. Por lo menos tú estás en tu carro y tú te montas en mi carro y tú no tienes nada que ver, ninguna relación con mi carro y tenemos una eventualidad y la cobertura mía te va a cubrir a ti, más allá de que no te nombro yo, hay una estipulación, así funciona ese seguro. Entonces cualquiera que se monte en la moto está cubierto más allá de que haya comprado o no la póliza él. Si se monta en la moto, perdón.

**Fer Molano**: Okay.

**F. Angles**: Lo importante sí es cargar los datos de la persona a quien se le va a avisar en caso de un siniestro. Exacto. Que son el beneficiario, o la mamá, o la novia, y el número de emergencia, esos datos sí hay que capturarlos. El número de emergencia va a venir por defecto, nosotros lo vamos a dar. Pero el número de la persona contacto sí hay que cargarlo. 'Mira, ¿a quién le avisarías en caso de que tengas un accidente?' 'Bueno, a mi novia, y el número es tal'. Eso hay que cargarlo.

**Fer Molano**: Okay. Listo.

**Thony**: Sí. Mira, también de nuevo con lo del tema de flujo de trabajo, déjame compartir unas pantallas aquí que tengo porque tengo caído el sistema aquí, no entiendo qué es lo que está pasando. Sabes, como siempre ese es el gusano del IT, ¿no? Déjame compartir aquí un momentico. Entonces, para complementar lo que estaba presentando Diego, y para pulir lo que tiene que ver con el flujo de trabajo... nosotros creamos un dashboard o una plataforma de Insurtech. ¿Okay? Que es la que corre en el IoT, que es similar a la otra que yo les mostré, pero esto está dedicado a esta arquitectura en particular. Entonces digamos que esta plataforma tiene dos bases de datos, una para el tiempo real para todo lo que es la data de tiempo real, y una para administrar documentos y la interfaz entre la compañía de seguro y Rueda Seguros, ¿no? Entonces, aquí desarrollamos un menú, no sé si se ve bien acá... que tiene varios niveles, ¿no? A nivel de, yo le puse aquí Quasar management porque es el nombre genérico, aquí va a ir Rueda Seguro obviamente. Entonces hay una visualización para la compañía de aseguradoras, otra para la compañía de emergencias, o lo que llaman First Responders, ¿no? La parte de clinical care, este ya es el hospital como tal, y la parte del Insurance Brokers. O sea, gente que ustedes van a estar teniendo para vender la aplicación aparte de eso, ¿no? Entonces, por ejemplo, este es el menú del Insurance Partner, en este caso tú vas a tener una agregación allí de toda la cantidad de motorizados que están confirmados operando... Entonces acá, la adquisición de la velocidad más los handovers, ¿no? Estos son la gente que está en un momento dado siendo rescatados y llevando a las clínicas. La parte del tipo de póliza si es básica, si es plus, si es premium como nos explicaste el otro día también. Y la liability, ¿no? cuántos casos tenemos corriendo en un momento determinado. La otra parte es el dashboard de los First Responders. Entonces ahí te dice si tiene una emergencia que viene de la aplicación, la aplicación te recoge el evento, tú lo captas aquí y se genera inmediatamente una alarma y la compañía de emergencia en este caso, debería estar pegada aquí y recibir la alarma de acá o directamente desde la aplicación. Okay. La otra cosa es el clinical care, entonces aquí va a estar sabiendo qué es lo que viene en camino. Si fulanito Julio Medina se cayó y se dieron su problema, y ya la gente viene acá y los va a tener allí en el triage, ¿no? Entonces va a saber dónde está la persona en un momento determinado. Y el último es el broker, ¿no? Cuántos suscriptores tiene esa persona en un momento determinado, las pólizas que están por vencer, las renovaciones que están por vencer. Entonces hay que enviarle una nota a través de la aplicación para que la persona o renueve la póliza o haga una resuscripción, cambie de plan, etcétera. Entonces tenemos que definir cuál es el flujo de trabajo que va en la aplicación y el flujo de trabajo que va en la...

**F. Angles**: Eso, eso te iba a decir, es más, deberíamos separarlos por bloque, deberíamos hacer el flujo de la venta, de este proceso de venta que es la parte que está haciendo Diego, me imagino, que es cómo va a funcionar todo eso hasta que muere esa venta, que es con el cobro ya de la póliza y después tenemos que ver aguas adentro de nosotros, o sea cuál va a ser el proceso, o sea, esto entra aquí, cómo se va a manejar, cómo se manejan los siniestros, porque sí, esa parte es importantísima que tengamos control de eso con este tipo de dashboard así. Sí, mira, una de las pestañitas que tienes que crear es compañías, porque esto lo vamos a vender a multicompañías, ¿oíste?

**Thony**: Ah okay, exacto.

**F. Angles**: Sí, varias compañías de seguro.

**Fer Molano**: Una pregunta, ¿en qué momento se sabe cuántas personas se cayeron en la moto? Cuando genera el botón de pánico...

**F. Angles**: Cuando el dispositivo activa... a la variable que le pongamos, el app que carga el teléfono se cayó, la velocidad, la frecuencia, y si el tipo se cae a una velocidad de impacto ya...

**Alex**: Y tiene que terminar y, y no apaga el botón de pánico, este... ingresa al sistema ya.

**Fer Molano**: Claro, pero eso si es una persona, ¿pero qué pasa si van con dos personas?

**Alex**: Bueno, cada dispositivo es independiente, uno te informa quién...

**Fer Molano**: No, pero si son dos personas dentro de la misma moto, dices tú.

**Alex**: Sí, sí, correcto.

**F. Angles**: Eh, no, mira, fíjate. Esta póliza el deber ser es que tenga dos tipos de cobertura, la de ley, que bueno, van y pelean al infinito y más allá para cobrarla, y la cobertura que de verdad va a funcionar, que es la que vamos a vender nosotros, que es probablemente sea solamente por el titular de la póliza, ¿okay? Eso tenemos que terminar...

**Fer Molano**: Ah okay, porque en los documentos que nos pasaron decía que era el titular y un acompañante.

**F. Angles**: Claro, porque la cobertura te cubre todos los que están montados en la moto. Pero lo revisamos, pero, pero sí, vamos a tener, el acompañante, yo creo que vamos a tener que ser indemnizatorio, un monto fijo y nada más al titular le cubriríamos un poco más. Eso, como diseño del producto tenemos que revisarlo.

**Alex**: Sí, okay.

**F. Angles**: Sí, hay que revisarlo porque el problema es que si agregamos, o sea, por ley tenemos que darle una cobertura a los dos, pero es una cobertura muy baja, ¿me entiendes? Queremos darle al motorizado una cobertura adicional, pero si agregamos a los dos participantes, la prima es doble, ¿me entiendes? Entonces ya, quizás se sale un poco del, del mercado que podemos atacar. Entonces, eso nos falta terminar, ajustar unos detalles ahí, pero ojo, la esencia del producto, o sea, va como lo que estamos hablando, ¿okay? O sea, lo que puede tener es que, o le pago a dos o le pago a uno, más nada.

**Alex**: O dividimos la cobertura entre los dos.

**F. Angles**: O dividimos la cobertura entre los dos, exacto.

**Thony**: De acuerdo. Ahí Diego, te propongo que termines de contarle a la aplicación, ¿no? Hasta dónde llega, para que... para que ese tenga la foto completa. Mmm.

**Alex**: Okay, perfecto.

**F. Angles**: Sí, vamos a... exacto, vamos primero con la parte de venta. Exacto.

**Thony**: Yo, Fernando y Alex y... y Fernando y Diego, yo tengo que irme dentro de doce minutos a otra reunión. Entonces, podemos hacer una reunión mañana, va a estar difícil, pero pasado mañana yo les puedo hacer el demo de la... de la aplicación IoT. Y este...

**Alex**: Okay, entonces vamos, vamos a ver qué, qué Diego avance rápido en estos doce minutos para que tú te lleves más información.

**Thony**: Sí. Dale, dale, perfecto.

**Alex**: Demuéstranos tu capacidad de síntesis.

**Diego**: Listo, entonces...

**Alex**: No, Diego, bien, porque la, lo más importante es vender.

**Diego**: Obvio. No, y que, y que ahorita... le moví una vaina y ahora como ya estoy registrado ya no me muestra lo de cotizar la póliza. Solo me muestra como, el dashboard cuando ya estás adentro. Se pueden ver los detalles de la póliza. El... un botón de, de emergencia para desactivarlo, ¿cierto? con... la ubicación. Pues ahí no, no pasó nada. Eh, la cotización pues... o... toca refinar estos planes, ¿no? para ver cuál es el precio final.

**Alex**: Eso, se refina y... exacto, lo que le agreguemos, perfecto.

**Diego**: Listo. Eh... los detalles de la póliza. Entonces... eh, yo me imagino que eso ya tendrá un QR funcional en el momento...

**F. Angles**: ¿Sí, no sé si te fijaste el carnecito que te mandé tiene un código QR? Vamos a, a replicar eso, ¿okay?

**Diego**: Okay, listo.

**F. Angles**: Que ese, con eso te verifica la, la policía si... de verdad funciona o no.

**Diego**: Claro, vi que algunos de los planes podrían incluir eh, grúa o, o detalles adicionales, ¿cierto?

**F. Angles**: Sí. Exacto.

**Diego**: Okay, sí, eso, eso ahorita no funciona, pero pues eso está ahí como para tenerlo en mente.

**F. Angles**: Okay, okay.

**Diego**: Eh... y pues, voy a igual ver otra vez el, el PDF que me acaban de mandar de la póliza para ver qué detalles faltan aquí que sean relevantes.

**F. Angles**: Diego, a mí me gustaría mostrarte, no sé si se puede hacer en esa reunión de mañana, me gustaría mostrarte cómo nosotros hoy emitimos una póliza de RCV normal, ¿okay? El, ese flujo, ese, ese, ese sistema lo diseñamos nosotros y, verga... cree... creemos que es la fórmula más fácil de hacerlo, ¿okay? Para ver si te puedes guiar por ese mismo camino, ¿okay?

**Diego**: Okay. ¿Ese es igual una aplicación móvil o es, o es qué, una...?

**F. Angles**: No, es, es web, es web.

**Diego**: Listo. Sí, hagámosle.

**F. Angles**: Exacto. Para que, para que te lleves eso, porque esa parte va a ser muy parecida, lo que vamos a agregar son unos, eh... unas coberturas adicionales. Pero esa venta es como la... esa, eso es como la manera más consolidada que tenemos. Recuerda que, en verdad para tú emitir esta póliza tienes que pedir una tonelada de datos más. Llegamos a un acuerdo con la compañía de que no tuviéramos que pedir tanto y no fuera fastidioso para el vendedor venderlo, ¿okay?

**Diego**: Ah, okay.

**F. Angles**: Sí claro, porque entonces estás escaneando no sé cuántos documentos...

**Alex**: Por eso, eso... exacto. Fíjate, por lo menos algo muy importante aquí es la dirección. Eh, ¿cómo lo solucionamos? Le metimos geolocalización y la dirección es la, lo que diga la geolocalización, y entonces nos saltamos un paso de que la persona ponga: 'Caracas, municipio tal, bla bla bla', ¿me entiendes?

**Diego**: Sí, sí, sí, de acuerdo, okay. Lo voy a implementar también.

**F. Angles**: Mmm, sí. Por eso te... por eso me gustaría enseñarte ese flujo, ¿okay? Ese... para, para que lo hagamos con eso. Después, es más, esa reunión mañana yo creo que va a ser un poquito larga. Me gusta...

**Diego**: ¿Y eso cómo se llama, esa herramienta?

**F. Angles**: Eh... esa, ma... es... es nuestra, es interna, a... un sistema Vareca. Es... noso... nosotros hicimos esa herramienta diseñada para los vendedores de calle que no saben absolutamente nada de seguros, ¿okay? Entonces, ellos venden, a partir de esa aplicación.

**Fer Molano**: ¿Y esa aplicación es solamente utilizada por los vendedores?

**F. Angles**: Solamente por mis vendedores, exactamente. Nosotros estamos desarrollando ahorita una parte que es para que, eh, puedan mandar un link y ese cliente final se autogestione esa póliza que es muy parecido a esto que vamos a tener, ¿me entiendes?

**Diego**: Sí.

**F. Angles**: O sea, nosotros tenemos una fuerza de venta muy grande que vende esta póliza de ley solamente, ¿okay? Que probablemente, esta fuerza de venta va a vender este producto de, de moto, ¿me entiendes? O sea, pe... perfecto para eso.

**Diego**: Claro, ahí... entonces, eh, en esta misma aplicación, ¿debería haber una vista para... para esos brokers? O sea, para los... los vendedores de póliza.

**F. Angles**: Fíjate, nosotros... Diego, para que te lo lleves ya de una vez. Nosotros te deberíamos tener dos formas de vender las pólizas: o con un broker o cliente final, ¿okay?

**Diego**: Sí.

**Alex**: Negocio directo, negocio directo.

**F. Angles**: Exacto, el, el, el negocio con el cliente final es el que se va a descargar su aplicación y la va a emitir. Pero el, el broker que venda o el vendedor que venda esto, tiene que tener un, una especie de portal donde él autogestione y le llegue a ese cliente final un link para que él descargue el aplicativo, pero ya con la póliza emitida, ¿okay?

**Alex**: Y hay otra, tres puntos, a pesar de que son dos actores en el sistema, tenemos que tener tres puntos de venta. El aplicativo para que el cliente final lo haga, el broker que lo haga y los POS, los puntos de venta que pueden emitir la póliza y yo te voy a mandar un, yo te los desgloso, te hago en otra, te hago en otra consulta de pago, que son puntos de venta que están en... 30.000 negocios, que cargando el... leyendo los datos pueden emitir imprimir un recibo de la póliza también. Esos puntos de venta también deberían conectarse con el sistema. Yo te voy a pasar los... los detalles técnicos.

**Diego**: Okay.

**F. Angles**: Claro.

**Fer Molano**: Sí, entonces tenemos que tener el vendedor, el punto de venta ¿y cuál otro?

**Diego**: Y el cliente final.

**F. Angles**: Y el cliente final. Como, como, como si tú bajaras un app en tu teléfono sin, sin ningún intermediario.

**Fer Molano**: Claro, ya.

**F. Angles**: Entonces, claro, cada uno es diferente. Por ejemplo, en el caso de, eh, de, de vendedor de póliza o de broker, este... probablemente tengamos que hacer un multinivel, porque yo como broker no vendo yo la póliza, la venden mis vendedores, ¿okay? Si nosotros le armamos una herramienta a los vendedores, a los... a los broker para que se lo puedan dar a sus vendedores y salgan a vender, es mucho más funcional, ¿okay?

**Diego**: Claro, okay.

**F. Angles**: Entonces, entonces por eso te digo, no sé... esa, esta reunión tenemos que hacer dos bloques, el bloque de ventas y el bloque administrativo. ¿Okay? Porque de los... lo de, en administrativo ya tengo varias cosas ahí también que, que, que, que les... que hay que agregar. Entonces, esta que tú mostraste ahorita, está perfecto, hay que ver cómo diseñamos el otro que yo, a mí me suena que el, el broker debería emitir la póliza y generarle un link que se lo mande al cliente, que el cliente descargue la aplicación y ya cuando entre a la aplicación, ya tiene la póliza emitida, ¿okay?

**Diego**: Claro.

**F. Angles**: Y él modifica ahí su botón de pánico, sus cosas, agrega, agrega más personas de, de que le avisen del botón de pánico, ¿me entiendes?

**Diego**: Sí, una pregunta. El, en Venezuela, el broker, bueno, el, no, el vendedor individual, ¿está identificado por algo? Digamos, si yo pongo en la pantalla de inicio 'entrar como vendedor' o 'entrar como cliente', haciendo ahí el ejemplo, ¿hay algo que identifique a ese vendedor, o cualquier persona podría registrarse como un vendedor y empezar a vender pólizas?

**F. Angles**: No, hay un código, hay un código. Tienen que estar, tienen que estar registrados ante la superintendencia.

**Diego**: Okay.

**F. Angles**: Sí, hay un código.

**Thony**: Una cosita, por... por tema de, de, de tiempo. Eh, ¿ustedes se pueden quedar un poco más?

**Alex**: Sí, vale. Yo me puedo quedar un rato.

**F. Angles**: Sí. Sí, sí.

**Diego**: Sí, sí. Listo.

**Thony**: Okay. Y lo otro que tú planteabas, Fernando, de contarle a Diego todo este detalle se le pudiera hacer de una vez.

**F. Angles**: Eh, déjame buscar, déjame buscar la computadora. Dame un segundo.

**Alex**: Okay.

**Diego**: Eh, y bueno, ahí, para seguir preguntando, eh... ¿y hay vendedores independientes o todos están asociados a algún broker?

**Alex**: Todos tienen que estar asociados a algún broker por ley. O... y, y lo que te dije de los puntos de venta, es un... porque son canales alternativos, que es un modelo nuevo que hay, que son aquellos que no son brokers, pero están habilitados por la ley para vender. Que son los, los supermercados, las farmacias, los... los puntos de venta que tienen... Hola. ¿Cómo estás? _(Saluda a Fabiola)_

**F. Angles**: Estás silenciado, eh... tigre, Toni. No la dejas hablar a Fabiola. _(Fabiola se despide)_

**F. Angles**: Eh... ya va, espérate. Déjame primero ver cómo entro al sistema. Ya va, porque... estoy igual que ustedes que el sistema no carga. No, no tengo usuario de ventas, huevón. Yo nunca vendo.

**Diego**: Eh, y... ¿hay alguna, algún broker inicial con el que hayan pensado trabajar como para guiarme de pronto en su documentación o en...?

**Alex**: Sí, con Vareca.

**F. Angles**: Con Vareca. Sí. Vareca es la sociedad de corretaje que tiene, que tiene los brokers pegados al esquema multinivel. Entonces con, con él sería el, el, el inicial.

**Alex**: Claro.

**Thony**: Una pregunta Diego, ¿tú ya terminaste de contar todo? De lo, de los...

**Diego**: Eh... sí, es que el resto creo que no va a cargar. Creo que por ahora sí.

**Alex**: Bueno, y la parte del sensor del giroscopio y todo ese tipo de vainas.

**Diego**: Ese es el siguiente paso. O sea, lo primero era como tener todo el onboarding.

**F. Angles**: Bueno, si quieres cuéntanos un poquito de eso para que Thony aproveche antes de irse...

**Thony**: Sí, hoy vamos a tomar ventajas de los sensores del mismo aparato, ¿no? de, de Diego.

**Diego**: Sí, claro. Claro, claro.

**Thony**: Entonces, digamos que la aplicación tiene que tener esa parte de telemetría y... como hablamos el otro día. Entonces tenemos que definir cuál es el... cada cuánto tiempo vamos a reportar a la IoT para que el IoT vaya analizando el comportamiento y nos dé, nos dé condiciones de falla, nos dé avisos de qué motorizado puede estar manejando mal, que sea reckless, ¿no? que llaman. O sea, un tipo que maneje azarado pues. Entonces, digamos que eso lo podemos sacar de la plataforma. Pero tenemos que... definir cada cuánto tiempo vamos a traer la data. ¿Cómo la vamos a recibir?

**Alex**: Sí, el, el tema de mejorar la conducta de, de manejo, yo lo tiraría para una segunda fase. Porque yo ahorita quiero que se suscriba la mayor cantidad de gente para que, para que el aplicativo tenga, tenga comunicación. No quiero ponerme estricto en, en el primer año, pues. Después el segundo año te enseño, te enseño a conducir bien. Pero en este primer año quiero ser masivo, porque la, la mayor cantidad de gente cuando sabe... Porque fíjate, el tema es, es un tema psicológico, nadie que ten... la mayor parte de la población que tiene una moto, no tiene cómo ir a un hospital ni a una clínica, y esto solucionaría eso. Pero entonces tengo que ser masivo. Porque se van a, se van a dar... van a haber 20.000 accidentes. Pero sobre 2 millones de motos. Entonces coño, eso...

**F. Angles**: Eso, eso es nada. Con la prima que hay, es un mercado que vamos a construir. Ese mercado no existe. Es un mercado que, haciéndolo bien, es de 200, 300 millones de dólares, que agarremos el 20, 30% del mercado es un dineral.

**Alex**: Claro, claro, claro.

**F. Angles**: Entonces por eso... y no solamente eso, eso es escalable, lo que está... lo que está haciendo Diego y lo que vamos a hacer nosotros es escalable a Latinoamérica, huevón. No es solamente a Venezuela. Por eso es que este... aquí se va a probar porque aquí es algo como más nuevo ahorita y porque nosotros tenemos acceso a todo, a todas las clínicas, a todos los proveedores, a todos los corredores. Pero...

**Thony**: Bueno chicos, yo me tengo que ir. Los dejo tranquilos por aquí.

**F. Angles**: Dale. Seguro. ¿A qué hora nos reunimos mañana?

**Thony**: Pasado mañana, mañana yo no puedo, pasado mañana.

**F. Angles**: Ah, okay. Vamos... ¿qué les parece... Ojo, no sé si les parece que mañana hagamos reunión de la parte de ventas con... con Diego para explicarle bien el proceso y pasado mañana nos reunimos contigo para la parte ya administrativa porque hay que agregarle 300 cosas ahí que ya se me ocurrieron de eso.

**Thony**: Bueno, buenísimo, buenísimo, yo te voy a pasar las pantallas, bueno ya están en el... te las paso al grupo y, Fernando, para que las vayan viendo mientras tanto.

**F. Angles**: Dale. De una. Dale pues. Seguro, hermano. Que te vaya bien. Mira, yo pensé que había mandado... ah, no iba a decir que mandaban las sobras, pero a Thony se fue. Le dijeron, de... 'a las 8 se cena en la casa'. ¿Me puedes mandar una invitación de link para acá? Para... para conectarme con esta computadora.

**Alex**: ¿Cómo es eso? ¿Cómo... me lo mandas por... el link me lo puedes mandar por WhatsApp a mí?

**Diego**: Está en el grupo.

**Fer Molano**: Diego, una vaina, en Venezuela se... se la pasa yéndose la luz, ¿la conexión de datos de moto se pierde frecuentemente o no?

**F. Angles**: No.

**Fer Molano**: ¿No?

**F. Angles**: No importa si la... o sea, puede haber un... Quiero pasarlo a WhatsApp. WhatsApp. Okay. Ya, deja... ya, ya, ya me voy a conectar, pero dame... O sea, sabemos que va a haber margen de error, ¿okay? Sí se va a perder conexión y va a haber, y va a haber un... Pasa a Arturo, pasa. Este... ¿cuál es, cuál es el usuario? acarpintero...

**Arturo**: Completo, sí, todito acarpintero...

**F. Angles**: Éste es el usuario.

**Arturo**: No, no, no, el usuario es mi correo, ya te lo doy...

**F. Angles**: Ah, okay. Y eso la clave pues... ah, la clave está arrecha.

**Fer Molano**: Yo, yo también me voy a tener que retirar en este instante, entonces eh... si quieren sigan ahí y mañana hablamos de la otra parte.

**F. Angles**: Chévere. Dale pues. Está bien.

**Fer Molano**: Dale pues. Chao, chao.

**Diego**: Listo.

**Arturo**: Porque, ¿con qué estoy...?

**F. Angles**: Bueno... mi correo, acarpintero... .vareca @gmail.com. Gracias, Arturo, me vas a salvar. No voy a emitir, no... lo voy a cancelar al final pues.

**Arturo**: No, no, tranquilo. No hay ningún problema. Dale. Voy a aprovechar para comentarte algo, que en un cliente... bueno no, ya, ya me acordé, es que el tomador es diferente, no listo, no tengo problema con el pago.

**F. Angles**: Ah, okay. Listo entonces. Fino, fino, gracias. Fíjate, Diego, eh, el tomador, que te digo, que eso es un tema que eso... hay que... hay que tenerlo bien afinado, ¿oíste? Esa parte. Pero... pero... epa, pero ten... por lo menos, te, lo que te digo, tenemos experiencia ya previa de, de dónde están los detalles que coño, nos va... nos va a ayudar mucho...

**Diego**: Sí, eso, eso ahorra todo el tiempo. Y... hay otra cosa ahí. ¿El GuíaPay es prioridad integrarlo?

**F. Angles**: No. No. Después te explicamos bien qué es lo que vamos a hacer ahí con eso, que ya lo, bueno, lo que estábamos conversando hoy. Ahí... ahí lo que vamos a integrar es un módulo que ya lo tenemos que es para que haga las... las indemnizaciones inmediatas y las verificaciones del pago. O sea, nosotros tenemos ya un desarrollo de que cuando nos caiga la plata nos avise, ¿okay? En esa... en esa transacción puntual. Te tengo que poner en contacto con el... con el chamo del sistema que nos desarrolla eso para que tú puedas...

**Diego**: Listo. ¿Pero entonces eso es con... pago móvil, cierto? ¿O no?

**F. Angles**: Pago móvil y débito inmediato, se llaman los dos servicios. Anótame ahí. Pago móvil y débito inmediato, se llama.

**Diego**: Okay.

**F. Angles**: Ahí está, listo, ¿ya no escuchas retorno, no?

**Diego**: No.

**F. Angles**: Ah, okay. Fíjate, te voy a mostrar lo que te estaba diciendo para que veas cómo funciona el de nosotros. Fíjate. Ahí, ¿ves la pantalla? ¿Todavía no?

**Diego**: Sí, ya.

**F. Angles**: Ah, okay. Fíjate. Claro, yo tengo esto diseñado para ir agregando otros productos después, pero ahorita lo que está funcionando es RCV. Fíjate, ahí está: "Vehículo", ¿okay? Yo aquí selecciono una, una selección previa, que probablemente en moto no tengamos que hacerla, que es si el vehículo es particular, si el vehículo es de más de tantos kilos. En la moto no hace falta esto, ¿okay?

**Diego**: Okay.

**F. Angles**: Pero probablemente sí tengamos algunas preguntas como este tipo, no que... no que transporta materiales corrosivos y esas cosas, pero sí debe tener alguna pregunta. Yo lo voy a verificar, a ver si tenemos que agregarle algo antes de eso, ¿okay? Si yo le doy aquí, con estas condiciones que yo le seleccioné, "Cotizar plan", él me da dos opciones aquí en este caso, que en el caso tuyo te dará los... los planes que tengamos, ¿okay? Fíjate que al... al de aquí de nosotros es muy sencillo, es "Sin grúa" y "Con grúa", ¿okay? Más nada.

**Diego**: Okay.

**F. Angles**: Okay. Entonces yo selecciono ese plan, y aquí es donde yo hago el OCR, ¿okay? Yo selecciono aquí... yo selecciono aquí un documento que... no sé si tengo cédulas aquí, permíteme un segundo. ¿Sí, no, huevón?

**Diego**: Y... ¿ustedes consideran que para el... el... el conductor de la moto es... es mejor que tome la foto en el momento o que suba el archivo?

**F. Angles**: Tiene que tener las dos opciones.

**Diego**: Claro, claro.

**F. Angles**: Tiene que tener las dos. ¿Tienes mi cédula ahí? ¿Si quieres pásamela? Ah, bueno, vamos a... y... y tómale una foto al carnet de circulación, a ese que te pasé, o mándamelo también. Sí. A ver si podemos... voy a descargarlo aquí. Eh... ya, espérate. Vamos a... Okay, descargar cédula. Y el carnet de circulación... okay, vamos a descargarlo también. Ya vamos a, vamos a hacerlo en vivo como... como debe ser. Carnet. Okay. Okay, fíjate, vuelvo aquí entonces a lo mismo. Ahora sí ya tengo la cédula. ¿Estás viendo ahí, no?

**Diego**: Sí.

**F. Angles**: Ah. Cédula. Yo agrego la cédula, y aquí... y aquí agrego el carnet. Nosotros, por tema de que tarda un poquito en hacer OCR, lo dejamos que... que pudiera ir montando todo a la par, ¿no?

**Diego**: Claro.

**F. Angles**: Fíjate, él aquí me toma los datos de esto. Fíjate, yo no saco de aquí fecha de nacimiento porque no lo necesito para la póliza de RCV, pero para la otra sí lo necesitamos, ¿okay? la fecha de nacimiento.

**Diego**: Okay. Sí.

**F. Angles**: Fíjate, él aquí me dice que el formato no está válido porque no leyó la V en el OCR, ¿okay? Otra cosa, yo pido aquí estado porque como estoy en un dispositivo que no tengo permitido, yo tengo que elegir aquí estado: Lara, municipio tal. Pero si lo podemos sacar esto por geolocalización, mucho mejor, ¿okay?

**Diego**: Okay. Sí. Entiendo.

**F. Angles**: ¿Okay? Fíjate. De aquí me saca placa, marca, modelo, peso, moto, uso, el tipo, el uso, el año, el color... todo eso, esos datos los tienes que sacar exactamente igual.

**Diego**: Sí, sí, sí, perfecto.

**F. Angles**: ¿Okay? "Datos del titular del vehículo", es el dueño del vehículo, ¿ves? Yo lo único que voy a poner aquí es correo. Que esto sí no lo podemos sacar de ninguna manera de OCR y el teléfono. Que aquí íbamos a poner datos de contacto de emergencia, que sería donde vamos a mandarle el mensaje.

**Diego**: O... o eso puede ser posterior. Eso puede ser posterior a esto. Aquí pídele los de la persona. Claro, acuérdate que él para registrarse ya le pidió el teléfono, ¿no? se lo vuelve a pedir.

**F. Angles**: Ah, no, claro, claro, claro. El teléfono ya está en el registro.

**Alex**: Sí, lo que tenemos que tener en una casilla ahí de... de datos de contacto de emergencia pues.

**Diego**: Listo, sí.

**F. Angles**: Vamos a ver. Colocar aquí en cualquier sitio. Ah, okay, aquí... aquí tenemos un tema con el serial del... del motor. Igual, ajá. Detecta... Ah, okay. Eh... fíjate, yo le seleccioné que la póliza era de automóvil particular, y en verdad es una moto, entonces él me dice: "Mira, plan de incompatibilidad detectada. Tu plan es este", ¿me entiendes? Y me lo selecciona en el plan de la moto. Por eso... ese error, si lo haces bien, no te va a decir eso, ¿no?

**Diego**: Claro.

**F. Angles**: Okay. Entonces fíjate, ya él te... él te hace una confirmación aquí que la hacemos nosotros para que la gente, si se equivocó en algún dato, que lo lea, que lo lea bien, que no se haya equivocado... Pasas la verificación y aquí es donde te pregunta, estas preguntas que son las que te comenté ahorita: "¿Quién es el conductor frecuente del vehículo? ¿El tomador, el titular o otra persona?" Si yo selecciono "otra persona", como te dije, él me deja llenar aquí estos datos. Si yo selecciono éste, bueno, ya es éste y punto, ¿okay?

**Diego**: Claro.

**F. Angles**: ¿Ves? Esto... esto es muy importante que lo hagamos para que la póliza termine de estar completamente... todos los datos que necesita ella. Y aquí... y aquí, cuando ya yo llego a esta parte, yo tengo dos opciones de pago: débito inmediato o pago móvil, ¿ves? Entonces, con cualquiera de las dos que yo seleccione, bueno, me va a pedir los requisitos que sean: el banco, tal, tal, y solicito el... y ahí... y aquí ya se emite la póliza.

**Diego**: Okay. Sí, sí, sí.

**F. Angles**: Como ves, es la fórmula como que menos cosas le podemos pedir al cliente.

**Diego**: Sí, sí, lo más fácil posible.

**F. Angles**: Exacto. Si se te ocurre a ti una mejor, chéverísimo, ¿sabes?

**Diego**: Okay. No, pero ahí está bueno, ahí está bueno porque son dos escaneos... seleccionar dos cositas más y ya.

**F. Angles**: Si... si quieres te hago un... si quieres te puedo hacer un usuario de este sistema para que lo escudriñes mejor tú...

**Diego**: Eh... sí, podría. Sí, igual ahí yo estoy... yo estoy tomando apuntes, pero sí.

**Alex**: Creo que... creo que Fernando estaba grabando la pantalla, entonces ahí...

**F. Angles**: ¡Ah, perfecto, perfecto\! Sí, claro. Si quieres te doy un acceso al sistema sin problema.

**Diego**: Dale.

**F. Angles**: Okay.

**Diego**: Y... y ya después de esta página... ¿ahí es donde el usuario puede ver la... la póliza? ¿O eso está ahí?

**F. Angles**: Exacto... Claro, ya yo después de que... de que yo selecciono aquí el banco y eso, lo que pasa es que aquí me va a cobrar si le doy... ya después de que yo hago eso, es que él me genera... él fabrica la póliza, exactamente. Y me... y me muestra el... tema de la... esas dos fotos que te pasé: el carnecito y la póliza PDF. A mí me gustaría que eso se lo reenviemos automáticamente o por WhatsApp al teléfono o por correo electrónico al correo electrónico que haya registrado, ¿me entiendes? También. Que lo pueda ver en vivo, que le salga en su... por... que en su portal él pueda descargar esa póliza, ¿okay? Porque esa póliza, como te digo... como es la póliza de ley, ellos tienen que mostrar la original, ¿me entiendes?

**Diego**: Entiendo, sí, sí, sí.

**F. Angles**: O sea, nuestro aplicativo móvil tiene que tener almacenado esa póliza y ese carnet.

**Diego**: Pero, ¿esa es la que les manda la aseguradora, no lo genera la misma página?

**F. Angles**: Lo... lo generamos nosotros, pero en verdad se supone que nos los mandó la aseguradora. La aseguradora, la aseguradora me dio carta blanca para yo generar la póliza, pues. Claro. Porque si no es muy difícil conectarnos. Sí. Hay aseguradoras que sí nos vamos a tener que conectar, ¿okay? Que sí probablemente vía API ellos nos respondan esta póliza.

**Diego**: Okay. Listo, sí, entiendo.

**Alex**: Yo te digo algo, para no tener tanto peo, yo... por lo menos las de Carolina haría que el API sea de nosotros, que se la devolvamos. ¿Y se aceptó vía API? Ah, Seguro Caracas. Seguro Caracas, nos manda su API. Eh, Seguro Mercantil, nos manda su API.

**Diego**: Sí, sería ideal.

**Alex**: Exacto. Y así ellos no hacen esto. Ni hacen esa distribución ni la discriminación ni nada. Y así Diego... claro, porque si... si, por lo menos, yo para vender esa vaina yo tengo que tener un... un ecosistema de todos los vendedores con... niveles. Una huevonada, si Diego va a hacer eso se va a volver loco.

**Diego**: Okay, entonces, a ver. Esto es prioridad. Todo... toda la parte de la venta y, por ejemplo, GuíaPay es para después, pero...

**F. Angles**: Eh, la integración con Venemergencia, con Áxel...

**Alex**: Eso es parte, esa es parte de la prioridad, sí, porque esa es parte del servicio. Diego, fíjate otra cosa que tienes que contemplar... nos va a pasar... eh, hay gente que va a querer vender este producto de manera masiva, por ejemplo, Vareca, ¿okay? Entonces, sería chévere que nosotros todos estos desarrollos que vayamos haciendo tengan APIs de manera de que lo podamos conectar a algunos sistemas de emisión que tenga alguien, ¿okay?

**Diego**: Okay, sí. Pero eso ya vendría más de la parte de... de Thony o directamente...

**Alex**: De nosotros. Como de la parte de los brokers, sería eso.

**Diego**: Sí.

**F. Angles**: Ojo, que yo lo veo muy fácil... ya tú después en sistema lo digieres a ver cómo sería. Yo creo que el deber ser es que nosotros llenemos todos estos campos, los mandemos vía API al sistema de Rueda Seguro, Rueda Seguro emita la póliza y le responda al cliente final con: 'descárgate el link para que bajes tu aplicativo que es donde tienes todos tus juguetes ahí', ¿correcto?

**Diego**: Sí, claro, y ahí ya entras con tu número, te llega un código OTP y ya estás adentro.

**F. Angles**: Exacto. Exacto. Y ya yo sé que bueno, eh... de este lado yo la emití y que ya el cliente se autogestione ya su parte de cómo ver, cómo ver todo eso.

**Diego**: Okay, listo, sí. Eh... a ver, déjame ver qué más preguntas tengo. Ahm... bueno, entonces, eh... ¿ustedes ya han trabajado algo de... de Venemergencia?

**F. Angles**: No.

**Alex**: No, no.

**Diego**: Okay, ¿no hay...

**F. Angles**: No sabemos, no sabemos cómo nos vamos a interconectar con ellos todavía. Pero... podemos pedir una reunión con ellos... pues, eso... podemos... eh... para, para ver cómo, cómo, cómo nos... o le preguntamos, pues, no sé, ya mandarle el mensaje.

**Alex**: Sí, sí, yo creo que si hablamos con... con el dueño y le preguntamos: 'mira, ¿cómo reciben ustedes las órdenes?' nosotros nos adaptamos a ellos. 'Ah, ¿que es un mensaje?' bueno, mandamos un mensaje. '¿Que es un correo?' bueno, mandamos un correo, ¿me entiendes?

**Diego**: Sí, sí, sí, perfecto.

**Alex**: Nosotros le decimos: 'Diego, ¿cuál va a ser el canal de comunicación y tú lo diseñas para que lo dispare en el momento oportuno'.

**Diego**: Okay. Eh... listo, sí, y... de aseguradoras, ¿la integración... ah bueno, no, ya dijimos, es correo, eh... o más bien... pues, al final del día, ¿cierto? por ahora.

**F. Angles**: Sí, sí, correo. Correo y teléfono, que además son chéveres para verificarlo.

**Alex**: Con la aseguradora es al final. Pero con las aseguradoras grandes va a ser... simultáneo.

**F. Angles**: Sí. Sí. Diego, nosotros tenemos, o sea... nosotros con cualquier compañía de seguro que lleguemos a un acuerdo, ya tenemos que hacer todo el match completo, o sea... ellos son los que van a emitir la póliza de RCV, pero van a necesitar que nosotros recojamos esos datos para ellos, ¿me entiendes? Y con cada uno nos conectaremos con un API distinto, porque es que cada compañía va a tener su API, ¿me entiendes?

**Diego**: Claro. Sí, sí, voy a asegurarme de hablar bien con Thony para que me pase los datos e integrar... la app con lo de atrás. Porque ese... ese API debería estar desde la parte... ah bueno, si... no, si es en vivo es desde la aplicación.

**F. Angles**: Claro, y re... y recuerda bien que ese API es solamente para la venta, nosotros en el... el transcurso normal de la operación, no necesitamos conectarnos con la compañía de seguro, ¿okay?

**Diego**: Okay. Por ahora, ¿correcto?

**F. Angles**: Al menos que ellos asuman una parte de riesgo.

**Alex**: Hay compañías que asumen riesgos.

**F. Angles**: Okay. Bueno, pero te... eso lo podemos ver a posterior. Eso...

**Alex**: No, claro, pero este... el, el, el dispositivo debería de informarle a la compañía.

**F. Angles**: Sí, claro. Pero te... coño, tendrías que hacer un panel para que ellos vean qué coño está pasando.

**Alex**: Claro. Sí, que eso es lo que está haciendo Thony.

**F. Angles**: Exacto. Okay. Mmm.

**Diego**: Sí, porque... ah bueno, un broker entraría al dashboard, no a la aplicación.

**F. Angles**: Exacto, un broker tiene que entrar a un portal donde él emita la póliza y genere su comisión y lo llevemos el registro de la comisión que generó, pero que le mande al cliente final el link para que el cliente sí se meta en la aplicación. O sea, este aplicativo debería ser única y exclusivamente para el cliente final.

**Diego**: Okay. Okay, o sea, sí, no debería tener una opción de entrar como...

**F. Angles**: No. No debería tener una opción de entrada, okay, listo. Exacto, la aplicación es para el cliente final, ¿que... qué es lo que queremos nosotros que pase en la aplicación? Nosotros queremos que en la aplicación el tipo tenga acceso a su póliza, vea su plan que tiene, lo mejore, lo empeore, lo que sea que vaya a hacer, eh... que tenga el botón de pánico con los avisos y que él pueda autogestionar y como las... las personas que... eso... eso... esas personas que él va a agregar en el momento de una emergencia. Por ejemplo, que se meta: 'mira, quiero que le avises a mi mamá, a mi papá, a mi abuelo, a mi tío'. Y a Venemergencia, si ya está configurado, parametrizado, ya que siempre le va a avisar, ¿okay?

**Alex**: Claro. Y que pueda recibir información para venderle otras vainas.

**F. Angles**: Exactamente.

**Diego**: Listo, sí, sí, sí, sí. Entiendo.

**F. Angles**: Entiendo, ahora sí estamos un poco más claros.

**Diego**: Sí, sí, bastante.

**F. Angles**: Entonces claro, Diego, ¿qué es lo que nosotros necesitamos ya después? Después de que se emita una póliza y que esté todo cargado, nosotros necesitamos esta información vaciarla en un sistema nuestro, que creo que va a ser lo que va a hacer... eh... ¿cómo es que se llama el señor? eh... Tony, perdón. Tony, este... Tony, o sea, nosotros tenemos que tener como una especie de ficha del cliente donde tengamos la cobertura que tiene, todo eso y que en base a esos datos nosotros podamos disparar esas alertas de cobertura o no cobertura, ¿okay?

**Diego**: Entiendo. Sí, sí, sí, claro. Y okay... Bueno... estoy viendo, eh... acordándome de lo de... lo de pago móvil, ¿hay alguna documentación para integrar eso?

**F. Angles**: Sí, sí. Te pongo, te pongo a hablar con el chamo de sistema para que integremos todo eso: pago móvil y débito inmediato, eso está facilito.

**Alex**: Eso. Claro, no podemos, tiene que ser en vivo, en un punto de venta.

**F. Angles**: En los puntos de venta. ¿Oíste? Hay una aplicación que se llama Biopago aquí que por los POS sí la podemos hacer, eso sería genial. Tú pagas con la huella digital y él te barre la cuenta del banco que sea. Tienes que decir la cuenta del banco.

**Diego**: Okay, entonces debería tener débito inmediato, pago móvil y Biopago.

**F. Angles**: Biopago, pero en los casos de los POS.

**Diego**: Ah, okay. Okay. Pero igual esta aplicación no es para los POS. Esa sería como la... la versión web.

**F. Angles**: No, no, no. Sí, la versión web, exacto.

**Diego**: Okay. Eh... bueno, pero igual puedo igual ir viendo un poquito de eso porque igual sigue la misma lógica.

**F. Angles**: Sí, exactamente. Sí, el flujo, el proceso es el mismo, lo que es que los canales de cobro son distintos. Y de venta. Porque es que en un... vender en un punto de venta una póliza de esto sería genial.

**Alex**: Los aplicativos los tenemos a disposición, tenemos a la gente que nos los da, que nos los pone, pero... eh... te voy a pasar incluso los detalles de cada uno para que los veas, pues.

**Diego**: Okay, sí, sí, para entender cómo es el proceso, o sea, digamos, cómo es el proceso cuando llega una persona a un POS, una persona lo atiende y le toma los datos y le emite la póliza.

**F. Angles**: Exacto.

**Diego**: Okay. Sí, está... está fácil.

**F. Angles**: Qué bueno.

**Diego**: Fácil, fácil, fácil, fácil. Nadie había... nadie me había dicho eso. _(Risas)_

**F. Angles**: No, no, epa... eh... Diego, lo que sí cuenta es que tenemos ya la lógica bien armada, o sea, para explicártelo... o sea, no es que te va a pasar como, me imagino que en algún proyecto te ha pasado, que 'no, después vemos a ver cómo'... no, no, aquí tenemos el... es más... nosotros, yo te puedo decir de punta a punta el procedimiento completo.

**Diego**: Sí, sí, por eso digo que es fácil porque no inicio de cero.

**F. Angles**: Exacto. No, y lo que sí tenemos que montar de forma conjunta es el otro, ya... ya la activación de... de la atención en sitio, la geolocalización, el tema del dispositivo, ya la segunda parte, ya el siniestro, pues, que es realmente lo que va a vender la póliza. Porque ese es el... Claro, esa parte sí es... es... esa sí... o sea, ahorita a mí me gustaría que nos enfocáramos mucho con esa parte de venta y de autogestión del cliente final. Del aplicativo, que se vea muy bonito, que sea muy chévere, que sea muy práctico, es más, si hay alguna herramienta que funcione ahí se la metemos, ¿me entiendes? O sea, no sé...

**Diego**: Como ¿qué tipo de herramientas? O sea...

**F. Angles**: No sé, hoy, hoy en día no te sé decir, pero, pero quizás si de repente nosotros tenemos una parte del portal donde hayan descuentos para los motorizados, en X tiendas concertadas que te... que tengan una especie de cupones ahí.

**Alex**: Okay. Y hacemos lo de... la rueda antes de la hora.

**F. Angles**: Exacto. ¿Me entiendes? Claro, ya no... ya no sería algo avanzado que tengo una interconexión, que tengo... no, no, no, quizás algo más de publicitario que otra cosa, ¿no? Imprimes tu cupón con un QR, pon cambio de aceite en la moto y vas para allá y lo cambias, no sé... eso sería después. Eso es como un marketplace de motorizado que podemos hacer en un momento.

**Diego**: Entiendo, sí. Okay, vale.

**F. Angles**: Por eso, son cosas que te digo que se nos van a ir... epa, ya yo sé que te vas a poner a pensar en diez. Pero sí, eso... eso cala bien en ese... acuérdate que si... si al cliente lo enamoramos, le damos más, más vida, ¿me entiendes? Más uso.

**Diego**: Ahí los perdí, los perdí un segundo.

**F. Angles**: ¿Ahora sí? ¿Ahora sí nos escuchas? Ajá, acuérdate que mientras más cosas puedas hacer en el aplicativo, le vamos a dar como más vida y más acceso y más interacción en ese aplicativo, ¿me entiendes?

**Diego**: Claro, más gente va a llegar a, por motivos diferentes.

**F. Angles**: Exacto. Va a tener más vida, pues...

**Diego**: Okay. Listo... eh... Bueno, no, creo que por ahora mis dudas están resueltas.

**F. Angles**: Dale, perfecto, entonces yo voy a... yo la documentación que tenga y de las cosas que he ido investigando, las voy a ir pasando en este grupo y la vas viendo.

**Diego**: Eso, sí. Sí, y más que todo de pronto la documentación de lo de los pagos...

**F. Angles**: Okay. Ahí para la documentación de los pagos te voy a dar el contacto de alguien para que te vaya diciendo cómo es, ¿okay? Y... probablemente él te va a pasar la documentación con una cuenta que tenemos abierta que está en funcionamiento, podemos hacer pruebas ahí si quieres, pero al final esta empresa va a tener su propia cuenta donde va a caer... pero va a ser la misma documentación, ¿me entiendes? Lo que va a haber es que cambiarle los parámetros de la cuenta.

**Diego**: Eso, perfecto. Sí, sí, sí, total, listo. Vale pues.

**F. Angles**: Dale pues. Bueno Diego, gracias por tu tiempo, mi pana.

**Diego**: No, igual a ustedes.

**Alex**: Cuadramos, cuadramos la reunión a la hora que ustedes... que nos digan. Nosotros no estamos disponibles, estamos trabajando en esto.

**F. Angles**: Sí, nos avisan. Coño, si tenemos algo bueno, lo rodamos media hora para adelante, para atrás, pero... pero nos cuadramos, avísanos.

**Diego**: Entonces mañana la idea es hablar ¿qué parte?

**F. Angles**: Ah no, pues, de verdad que si quieres adelantamos bastante con la parte de ventas, si quieres... hacemos una reunión el miércoles...

**Alex**: O sea, lo único Diego que yo te podría decir que si quieres lo revisamos de una vez es, plasma el flujo escrito a mano, pero de punta a punta, no sé si lo quieres hacer, o quieres ir diseñando algo en base a lo que ya tienes y lo vamos viendo después, pero sabes que sería bueno, que te lo podamos creer el usuario para que él navegue y pregunte las preguntas...

**F. Angles**: Claro, claro, claro. Ahorita te lo mando a crear.

**Diego**: Sí, igual lo del flujo sí me parece bueno para no estar como... saltando.

**F. Angles**: Coño, porque es que si yo sé que si escribimos eso de punta a punta, ya tú, las preguntas no se... o sea son mucho menos, ¿me entiendes? Danos el día de mañana para escribir el flujo para pasártelo el miércoles para ponernos a la gente a que trabajemos en...

**Diego**: Sí, sí, sí. No, y ya tengo una noción, pero son los detalles los que... Eso. Sí, sí. Y así yo también voy, voy revisando las mejoras de la aplicación.

**F. Angles**: Sí, le echamos el cuento al que hace la... los flujos de nosotros y que nos los monte más o menos para que tengas algo mejor...

**Alex**: Sí, sí, porque yo sabía, yo lo tengo en mi cabeza, pero para escribírtelo, verga... tengo que poner una hoja de papel en la pared y empezar a rayar.

**Diego**: Sí, sí, no, de una. Listo.

**F. Angles**: Dale pues, cuídense.

**Diego**: Dale.

**Alex**: Un abrazo, chao. Cuídate.

**Diego**: Chao, muchas gracias.
