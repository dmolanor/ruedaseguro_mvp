### **Transcripción Reunión**

**Thony:** Coño, ahora sí te veo perfecto.

**Fernando:** Ah, qué bueno. Mira, este... ¿tú por qué pones un león ahí cuando tú eres un tigre?

**Thony:** (Risas) Porque mi hijo le puso un león allí, y dejé el background, caracha. Sí. Espérate un momentico, déjame abrir lo que yo tengo aquí para mostrarte algo. Ya va.

*(Pausa)*

**Thony:** Ya va un momentico. Estamos. Okay, entonces fíjate. Yo lo que tengo acá... Déjame ir para, para la parte de... para ir echándote el cuento de lo que, de lo que yo estaba pensando y este... ¿cómo se llama? Comenzar a crearnos una arquitectura, ¿no? Para discutir esa arquitectura con esta gente. Porque de alguna manera yo lo que estaba pensando también es que necesitamos... eh, ya va, un momento... Es que necesitamos darle una, una fundación para la discusión, ¿no? A esta vaina. Aquí está. Entonces... no, esta no está cobrando. Disculpa, ya va, Fernando y Diego, ya va. Un momentico.

**Fernando/Diego:** Eh, un segundito que nos estamos uniendo desde el computador.

**Thony:** Vale, vale.

*(Pausa)*

**Fernando/Diego:** Okay, ya estamos aquí en esta.

**Thony:** Vale, vale, ¿ya están ahí viéndome? Okay. Entonces yo lo que... lo que estaba pensando el otro día era que nosotros debemos presentarle una especie de arquitectura a estos chicos, donde nosotros podamos usar esa arquitectura para... para plantearles a ellos una, una visión de lo que hay que hacer, ¿no? Porque obviamente se supone que nosotros somos los que sabemos qué es lo que deben... qué es lo que necesitamos, ¿no? Entonces, desde el punto de vista de, de arquitectura, nosotros tenemos dos cosas, tenemos la... tenemos varios elementos...

**Fernando/Diego:** Eh, deja, déjame que cargo con la cámara... Sí, pero yo la tengo de frente...

**Thony:** ¿Se ve?

**Fernando/Diego:** Eh, sí sí sí, dame un, dame un segundito aquí... ¿Tú me estás viendo aquí o no?

**Thony:** Ahora sí los veo, perfecto, a los dos.

**Fernando/Diego:** Okay, listo, perfecto. Ajá. Listo.

**Thony:** Muy bien. Entonces fíjate, yo lo que quería era plantearles a ustedes dos que nosotros agarremos y digamos... bueno mira, nosotros tenemos una arquitectura, tenemos la aplicación, tenemos la fundación de datos, y tenemos la compañía de seguros como tal. Entonces digamos que en término, en términos de arquitectura, y ustedes me van corrigiendo si están de acuerdo o no, ¿correcto? Entonces en términos de arquitectura, la fundación de datos tiene un... un módulo de ingestión de datos, una base de datos, tiene la... la interfaz con la compañía de seguros, y tiene la parte del bitcoin...

**Fernando:** Eh, eh, eh, espera, lo del bitcoin es una mariquera, o sea esa vaina... o sea sí sí sirve, pero se puede, pero él lo puso fue pa' que sonara bonito, no porque sea... no es porque sea necesario pues.

**Thony:** Exacto, pero para la parte de, ¿cómo se llama? de bitcoin aquí, de transacciones y tal, seguras, bueno... la plataforma que, que tenemos ya de la fundación de datos ya tiene toda esta... toda esta parte hecha, ¿okay? Y hasta ahora soporta 4.000 assets... 4.000 motorizados, ¿okay? En cloud. Entonces, la parte de... digamos que esta es la parte de arquitectura, obviamente todavía no hemos hablado de flujos, ¿no? Ahora en términos de aplicación, entonces aquí es donde está todo lo que tienen que ustedes ir haciendo, ¿no? En la parte móvil, y debemos tener una interfaz de integración de datos acá, con esto que es con MQTT o AMQP, uno de estos... uno de estos protocolos de... de IoT. Entonces, cuan... acá debemos de, ¿cómo se llama? definir qué es lo que nosotros pensamos que va a estar, qué es lo que se va a hacer a nivel de la aplicación, y qué es lo que se va a hacer a nivel de la aplicación de fundación de datos. Porque nosotros lo que vamos a tener con la compañía de seguros es interacción para... definir la cantidad de motorizados que tenemos, transferir la información, validar las pólizas y todo ese tipo de vainas, que es la parte del workflow que tenemos que definir, y nosotros debemos también crear aquí una descripción de lo que... de lo que vamos a hacer aquí en la app. El alcance de la app, ¿no? Entonces qué se hace aquí y qué se hace acá...

**Fernando:** Eh... espérate, ahí hay más cosas aparte de la app. La app es un pedacito, pero también están los dashboards. Y también está... que es dashboards, tanto para las... para lo que ellos llaman los... eh, el el oráculo, ¿no? y para Rueda Seguro, ¿no? Hay que tener un dashboard con el cual tú controlas toda la información que se está manejando allí, ¿no? que es aparte de la app, ¿no?

**Thony:** Entonces digamos que lo que ustedes están envisionando es que acá en la plataforma tengamos esa visualización, y que la parte de la app móvil tenga la interfaz de usuario. ¿Eso es lo que estamos pensando?

**Fernando/Diego:** Sí, es similar a lo de Quasar.

**Thony:** Correcto, porque fíjate en lo de Quasar... ya va... Esta Quasar IoT Platform es la fundación de datos, ¿no? Entonces... qué carajo está esa... se me volvió a perder. Aquí está. Campaña con Tony Robbins... no, otra... Tony Brito... el hermano de Alan Brito. (Risas) Entonces fíjate, aquí lo que hay es una... ¿cómo se llama? es un módulo que tiene su... de nuevo, tiene una ingestión de datos, tiene base de datos, pero tiene unos dashboards muy básicos, que... que yo creé basado en una, ¿cómo se llama? una aplicación muy general. Acá tenemos lo que es la... la, ¿cómo se llama? el storage de las pólizas, un monitoreo de los eventos cuando el motorizado se cae, cuando tiene una aceleración, una desaceleración, cómo nos vamos a integrar con la plataforma de datos y todo esto allí, ¿no? Y aparte de eso, entonces aquí hay que crear unos dashboards con la cantidad de motorizados y assets que tenemos, dónde están, y fíjate que aquí hay unas... unas, ¿cómo se llama? unas... unos dashboards muy, muy, muy básicos, pero que ellos nos digan bueno... eh, a dónde vamos a pasar esa, esa información desde el... que viene del motorizado, que viene de la app, que viene de la base de datos de acá, que es una data... una base de datos Postgres, SQL, este, viene de allí rendidora, y todo en Google Cloud. En Caracas... yo lo... digamos que lo preparé para la cloud que funciona allá en Caracas, ¿no? Entonces bueno, ellos de aquí en adelante ellos nos tienen que decir, o en este caso ustedes también me tienen que decir, bueno qué vamos a tener en la app a nivel local y qué vamos a tener en la... en la fundación de datos, que es el dashboard. Aquí en este Insurtech Plugin, como lo llamo yo, es donde iría toda la información relacionada con los seguros, pólizas, suscriptores, este... eventos, eh... y el el workflow manager, ¿no? que habr... habría falta aquí... haría falta ponerle un workflow manager ahí, de tal manera que cuando hay un evento él genere un flujo de trabajo, que te genere la famosa... ¿cómo se llama? El famoso... el famoso workflow para que alguien autorice la... primero que todo la inspección y después el pago de la póliza. Entonces digamos que... este digamos es muy básico, como dices tú Fernando, pero lo que necesitamos ahora es especificaciones para poder di... diseñar estos dashboards y las... ¿cómo se llama? Los cinco niveles de pantalla, ¿no? Que es overview, detalle, grids, alarmas, todo eso, ¿no? ¿No sé si tiene sentido lo que estamos conversando... lo que estoy mencionando? Obviamente de nuevo, muy básico, pero este es el plugin de la plataforma... de la fundación de datos y lo que yo estoy pensando es que esta tenga su propio... ¿cómo se llama? Módulo de ingestión de datos, su propia... sea independiente de la otra plataforma que es más industrial, ¿no? Entonces para no mezclar una cosa con la otra y tenerlo como parte de nuestra iniciativa. El... mi último punto que les iba a comentar... es que eh... una plataforma como esta te cobra entre 5 y 10 dólares por asset mensuales, ¿okay? Entonces si tú tienes 5 a 10 dólares por asset mensuales y tienes eh... 10... 10 mil motorizados, eso son 600 mil dólares al año, ¿no? Que se pudiera manejar, obviamente en suscripción. Eso sin contar la parte de... de de de servicios, onboarding y las otro tipo de cosas. Entonces, para tener un benchmark de cómo podría la conversación comenzar a ocurrir, nosotros pudiéramos usar esos benchmark para la parte de conversaciones con con Alex, ¿no? Entonces bueno, nosotros decimos bueno, ¿somos un proveedor o somos un accionista? Honestamente a mí me interesa ahorita más generar cash que que tener acciones, pero bueno, no sabemos hasta dónde puede llegar esto.

**Fernando:** A ver, esa es una conversación que yo tuve ya con Alex, o sea, él lo que me dijo fue, Fernando, yo tengo quién haga esta vaina... o sea, yo estoy haciendo esta vaina con ustedes porque son mis panas. Pero yo no, yo no necesito proveedores. Yo tengo ya, yo tengo aquí una gente técnica que me lo pudiera hacer, ¿no? Y sí que es así, pues. O sea, porque él ya viene trabajando algunas vainas y... lo que fuera, ¿no? Entonces... mmm... yo creo que aquí la conversación va por otro lado, es... venga, sentémonos, saquemos los números, veamos cuál es el equipo, quiénes son las personas que están metidas en este tema y eh... porque... Alex no tiene de dónde sacar plata pa' pagar esto. O sea, pa' pagarle a proveedores, ¿no?

**Thony:** Claro.

**Fernando:** Entonces, el, el asunto es... definamos... yo no sé yo no sé, sé que estamos nosotros tres pero él tiene a otra gente allí al lado de él, ¿no? Eh, que que está trabajando esta vaina, entonces es como... sincerar y decir, mira no, sabes qué, hay siete personas metidas en este proyecto y mira, este carajo es el de seguros, este es el de tecnología, este es el de finanzas, este es el de la vaina, pin, pum, y definir claramente los roles y con base en eso decidir, ¿vamos o no vamos? Creo que este es un tema medio binario. Vamos o no vamos... eh, según lo que acordemos de: 'Ah no, mira, es que este negocio se puede valorar y este negocio puede generar dos millones de dólares al año y puede tener esta valoración y, y definir los porcentajes de participación'. Y si no nos interesa, sencillamente, no vamos. Punto. Así lo veo yo. Y claro, lo que tú dices de cuánto cuesta vender la base de datos y esa vaina será relevante, ¿cierto? Para que uno pueda cuantificar cuál es el esfuerzo de uno. Pero creo que esto viene más por el lado de... este es un emprendimiento que pudiera tener tal retorno y a mí me interesaría que, no sé, en dos, tres, cuatro años, uno decir, soy dueño de una vaina que vale 8 millones de dólares, ah bueno, eso... Yo lo estoy viendo de esa forma y creo que así es como lo ve Alex también, ¿no?

**Thony:** Bueno fíjate, honestamente yo tengo, yo pienso que... que... todo va a depender del caso de negocio grande, ¿no? Y de sentarnos primero a ver la... como dice un amigo mío, el bosque, después ver los árboles, ¿no? Porque digamos que la parte técnica ya la tenemos hecha. Eh eh, es fácil, digamos con las herramientas que existen ahora. Entonces lo que tenemos que comenzar a pulir y... y conseguir un COO, como lo llamo yo, un back-end, un back office que se encargue de hacer mantenimiento diario, que esa es la parte de operaciones. Ahora cómo... eh... ¿hasta cuánto provecho hay que hacer? ¿cuánto es la parte de de inversión que se necesita allí más allá de la parte técnica? Porque tiene que haber un... un driver, ¿no? También para, para esto. Si se conocen mejores prácticas y... no todo el mundo puede desarrollar una vaina buena. Esa es la otra cosa.

**Fernando:** Mhm. Sí, a ver, si tú me preguntas yo no estoy tan claro... de cuán claro está Alex en cuanto a... lo que se requiere para que este proyecto sea exitoso, es decir... 'mira, eh... huevón, para que esta vaina comencemos a venderla hay que gastarle no sé, 50 mil dólares, ¿y quién va a poner esa plata?'

**Thony:** Exacto.

**Fernando:** Yo... yo nuevamente creo que las conversaciones va por ese lado de venga, vamos a poner los números, vamos a hacer, a entender bien el proyecto, eh... y con base en eso decidimos si el aporte de uno va a estar es en... en horas hombre o hay que poner plata, hay que poner plata en la vaina.

**Thony:** Claro, claro. Fíjate, Fernando... yo también tengo ahí una... una cuestión, ¿no? Lo que es la parte de, una inquietud... que yo no tengo intenciones ahora de poner plata en... en este tema de este Insurtech porque no es mi... no es mi fuerte, ¿no? Sino más bien en la parte de, de desarrollo de aplicación, ¿no? Y este... coño, la parte de industrial que eso sí me interesa a mí, ya la otra plataforma está muy, muy sólida. La otra plataforma de... de la otra fundación de datos... que coño, te soporta un sistema grande, ¿no? Y la... para de... para darte una idea, para desarrollar una plataforma similar en la compañía donde yo estoy terminando de trabajar ahorita, porque también trabajo ahí hasta el 31 de marzo...

**Fernando:** Ah sí, ¿también te dijeron que ya... se acabó?

**Thony:** No, la, digamos que el joint venture termina el 31 de marzo, pero no sé si voy a pasar a la otra empresa porque las condiciones están allí más o menos...

**Fernando:** ¿Ah, o sea que todavía no se te ha confirmado lo de Schlumberger?

**Thony:** No... ellos ya me ofrecieron. Entonces bueno, mañana vamos a tener una discusión final a ver si me... me uno o no me uno. Entonces, pero... ¿tú sabes cuánto se gastó esa compañía en construir una plataforma similar a la que nosotros tenemos aquí que... que te mostré el otro día? Se gastaron 20 millones de dólares... en diseñar la arquitectura y, de hecho mañana tengo una reunión bien temprano con el... con uno de los arquitectos para revisarla porque vamos a comenzar a probar el performance... Entonces... eh digamos que no es trivial desarrollar algo así como lo que quiere Alex para manejar 10 mil motorizados. Manejar 10 mil motorizados, dependiendo de lo que es la frecuencia de datos y la... los dashboards y toda esa vaina, requiere una inversión y un... y una especialización en, en conocimiento, ¿no? Porque es como dices tú, no es solamente desarrollar la app en el teléfono, es todo el ecosistema... es todo el ecosistema.

**Thony:** ...el workflow que hay que crear y toda la descriptiva que hay que crear para poder hacer la plataforma. Y en, en ese sentido, coño, eh, no, no, no se puede subestimar el, el valor de la, de la tecnología que se está trayendo.

**Fernando:** Okay. A ver, eso que tú estás diciendo me parece bastante importante para hacérselo saber y entender a Alex, ¿no? Eh, digamos que... mm... de repente en esos términos como tú lo estás planteando, de decirle, ven Alex, o sea, aclaremos bien la vaina porque nosotros podemos montar una vaina bastante robusta, bastante bien hecha... este, y no es solamente generar una base de datos en SQL, eso no es lo que se necesita, se necesita unas cosas un poco más robustas que esas para manejar un sistema como este. Entonces... mm... definamos bien con base en eso. ¿No?

**Thony:** Claro, exacto. Y mira, yo lo que puedo hacer ahora es generar un, un documento de, de especificación de este, de este plugin, ¿no? Para que ustedes lo vean, lo, lo lean. Pero de nuevo, esto, porque uno lo conoce de repente uno piensa que es sencillo, pero esto no es información que está muy, mucho a la mano de, de gente común, pues, y desarrolladores básicos. Entonces, coño, por ejemplo la parte de resiliencia, ¿no? Del, del sistema. Cuánta, cuánta data traer a cierto momento, la parte de la, de diseñar la, la, el bandwidth, la fortaleza de la base de datos, la... ¿cómo se llama? La alta disponibilidad. Porque si se te cae un servidor, ¿dónde tienes toda la data? ¿Cómo te comunicas? ¿Si tienes OPC UA o tienes API para comunicarte con el SAP? O el Máximo, no me acuerdo cómo es que se llama el software que dijo Alex el otro día. Entonces, digamos que todo eso, eso es plata, mira. Para implementar una, una plataforma así, la empresa donde yo trabajo pues cobra 250.000 dólares en, en horas hombre. 250.000 dólares en horas hombre, sin contar el software, que el software cuesta 10 dólares por, por asset... por mes. Esa es la, esa es la tarifa del mercado internacional por una plataforma así. Entonces, bueno, digamos que nosotros podemos valorar el, el esfuerzo coño, no poniéndole precio norteamericano pero sí unos precios más tropicales y, y hablar en función de eso, pues.

**Fernando:** Okay.

**Thony:** Entonces con el arquitecto que yo tengo, de hecho de nuevo el, este, el... y mañana yo voy a valo... a revisar unas cuestiones. La otra, la plataforma hermana de esta... porque esta es la prima, ¿no? Esta es la hermana chiquita. La plataforma grande, yo la voy a lanzar ya oficialmente o la voy a presentar a un cliente el 3 de marzo y un demo pasado mañana, aquí en Abu Dabi.

**Fernando:** El 3 de abril...

**Thony:** El 3 de abril, perdón. Este... pasado mañana la vamos a presentar porque los tipos quieren comenzar a revender eso aquí, y el precio de esa plataforma en la calle aquí en esta parte del mundo son 15 dólares por asset... por mes. En contratos de tres años. Y normalmente son 100 assets. ¿No? Pa' empezar. Y a parte de eso la parte de servicio, la parte de conexión... etcétera. Entonces, digamos que ese es el valor de la tecnología que uno está trayendo aquí bajo la mesa... sobre a la mesa, ¿no? Entonces la otra cosa es, okay, cuánto, yo me voy a callar un momentico aquí, Fernando. Este... ¿cuánto se puede cobrar por una póliza a un motorizado de esos? Y, ¿cuánto, y ese costo de esa póliza tiene que estar, eh, tiene que asumir lo que nosotros tenemos aquí, que es el backbone de la operación?

**Fernando:** Mira... mm... yo no creo que por la póliza completa... y eso lo podemos validar con Alex. ¿Verdad? Yo pensaría que esta póliza debe estar por el orden de los... al año. ¿No? Una póliza anual. Yo creo que esta vaina debe estar por el orden de los 100, máximo 200 dólares al año.

**Thony:** Okay, okay.

**Fernando:** Eh, y cuidado si es menos. Cuidado si es menos, porque son motorizados, ¿no? Este...

**Thony:** Claro.

**Fernando:** No, de hecho, sí... yo creo que más bien te hablaría que puede estar entre los 50 y 150 dólares. O sea, aplicando aquí lógica latinoamericana, huevón. Puedo estar totalmente equivocado. Pero básicamente, porque aquí una póliza eh... médica... eh, por mi familia, yo pago más o menos... 100, 150 dólares al año. Ah no, mentira, no, espérate, no, estoy, estoy pelado, espérate... pin pum pan... pan... sí, 100...

**Thony:** Esa es la vaina de cuando uno tiene muchos riales, pana.

**Fernando:** Cuando tengo mucho rial... o, o más bien eso me pasa cuando uno tiene una esposa que maneja todas las cuentas... (Risas)

**Thony:** Lo mismo me pasa a mí... (Risas)

**Fernando:** Okay. No, pero es que, lo saqué por dos perspectivas, pero una la tenía equivocada. Una es la póliza de, aquí la póliza de responsabilidad civil, que aquí se llama SOAT. Aquí se paga más o menos un millón y pico al año, que eso son ponle que 350 dólares. La póliza de responsabilidad civil. Este... ¿Eso es lo que estaban mostrando ellos, o no? Seguro Caracas... plan de... Estos, esto es, ¿estos son mensuales o anuales? Espérate que Diego me está mostrando aquí unos valores.

**Diego:** No sé por qué... ah, sí, creo que es anual. Anual.

**Fernando:** Sí, aquí me estaban moviendo unos valores super bajitos, pero yo sí creo que una póliza de este tipo, considerando que son mensajeros, huevón... yo no creo que tú puedas cobrar más de 100 dólares. Yo creo que si te pones a pensar, 100 dólares... puedes cobrar al año, porque a esa gente no le sobra plata, huevón.

**Thony:** Claro.

**Fernando:** Y de ahí tiene que salir... para cubrir Rueda Seguro... para, y para cubrir los siniestros. Y para manejar el nivel de ganancias de la aseguradora, ¿no?

**Thony:** Claro.

**Fernando:** Este... entonces... esto es una vaina de bajo margen, pero alto volumen. ¿Mhm?

**Thony:** Correcto.

**Fernando:** Que esas son preguntas que le podemos a ir a hacer a Alex y... y entrar a ver los numeritos. Sí, a ver, una vaina. Cuando tú estás hablando de un tema industrial, tú, los costos se diluyen porque tu, el ingreso es tan alto que tú necesitas que los equipos estén todo el tiempo operativos y, y monitoreados, y porque te ahorras a un empleado haciendo inspección y vainas por el estilo. Cuando estás hablando de motorizados, es un producto de consumo masivo y... y lo que quieres es prevenir costos, no maximizar ingresos, ¿no? Entonces... es un poquito, yo creo que es bastante diferente. Yo creo que si tú piensas, cuánto es el valor de la tecnología por cada uno de los motorizados, a lo mejor puedes estar hablando de... uno, dos dólares al mes.

**Thony:** Cinco dólares al mes.

**Fernando:** ¿Cuánto?

**Thony:** ¿Uno, dos dólares al mes?

**Fernando:** Mhm, mhm.

**Thony:** ¿Tú cuánto me hablabas de que eso cuesta 15 dólares? ¿Ese era mensual o anual?

**Fernando:** Mensual. Pero para la industrial, como dices tú, de repente para un producto de consumo masivo, esta vaina no puede pasar de 5 dólares. Coño, pero 5 dólares es significativo, si te pones a ver.

**Thony:** Exacto, pero yo no veo 5 dólares al mes. Lo vería como mucho, o sea eso son 60 al año, eso es lo que te cuesta la póliza. Entonces... digamos, estoy inventándome aquí números, pero por mi lógica a un mensajero no le va a pagar esa vaina. Aquí en Colombia, hay un peo y es que las pólizas de responsabilidad civil, ¿no? Este, el gobierno ha tenido que bajarlas, e incluso subsidiarlas, porque los motorizados prefieren no contratarla, e ir ilegalmente... van ilegalmente. Porque no quieren sacar la plata para esa vaina, prefieren comprar leche para la casa, huevón.

**Fernando:** Claro, claro. Y ¿cuál es la cobertura de esa póliza? En un, una...

**Thony:** O sea, la del SOAT es la de seguro obligatorio... y ese básicamente es un... cubre daños a terceros. Es como la responsabilidad civil venezolana, más o menos. Te cubre daños a terceros. Y eso es obligatorio, igual que la responsabilidad civil en Venezuela, es obligatorio. Aquí para una moto, yo creo que está costando aproximadamente como unos 150 dólares al mes... digo, al año. Y el peo es que esos son los que tienen más siniestros, ¿no? Entonces... este... aquí siempre ha estado esa discusión, el gobierno por populismo bajó el valor de la moto, entonces... terminan subsidiando las motos, e igual los motorizados siguieron sin contratarla.

**Fernando:** Aquí dice... 150 dólares al año.

**Thony:** Mhm, mhm. No, aquí...

**Fernando:** Mapfre de Colombia... 150 y 600... si es una Gold Wing o...

**Thony:** Mhm. Sí.

**Fernando:** Entonces aquí dice, cubre un seguro para motor... bla, bla, bla, la vaina... Pero fíjate que eso no cubre el daño de la moto ni... el de la moto, ¿no? Eso es... no es un seguro de la moto, si es un seguro de responsabilidad civil. Mhm.

**Thony:** Aquí dice, problemas relacionados con la motocicleta, responsabilidad civil, protección contra robos, daños... cobertura de accidentes personales y asesoramiento legal. Este es Mapfre de Colombia.

**Fernando:** Sí, mira, estamos leyendo aquí la responsabilidad civil en Venezuela, ¿sabes cuánto cuesta? De Seguros Pirámide, huevón. Te cagas.

**Thony:** ¿Cuánto? ¿10 dólares?

**Fernando:** El básico 17 dólares al año.

**Thony:** Claro.

**Fernando:** Dólar y medio mensual. Y el pro, 31 dólares, o sea, el pro son dos dólares y pico mensuales.

**Thony:** Verga, ¿entonces qué tendríamos que cobrar? ¿Un dólar por esta vaina?

**Fernando:** No joda... No, centavos... o sea, 10, 20, 30 centavos. Porque si no... ¿quién paga los siniestros, huevón?

**Thony:** Pero yo te digo una cosa así, coño el precio del software es lo que uno le quiera poner, también depende de lo que llaman el, el caso de negocios, ¿no?

**Fernando:** Mhm.

**Thony:** Es el caso de negocio en este caso, sí son... algo así en ese... en ese tenor, ¿no? Entonces, coño, uno puede poner una, una plataforma así, cloud, tiene que ser cloud para que no, no haya que gastar plata en servidores ni nada de eso.

**Fernando:** Sí.

**Thony:** En Google, y el precio de Google es .0000332. Okay, entonces sí se pudiera hacer algo así, coño. Y todavía es algo decente, porque son coño un dólar al mes son 60.000 dólares... ¿cuánto es al año? Por 10.000 motorizados, 120.000 dólares, todavía, todavía es plata, pues.

**Fernando:** Sí.

**Thony:** Entonces vale la pena, o se puede hacer una... en vez de pagar, en vez de cobrar una... una suscripción se cobra una, una perpetuidad allí pues, un paquete y se acabó.

**Fernando:** Sí, de acuerdo. ¿Alex no se va a unir? Este... eh...

**Thony:** Ese es mi celular... ah, préstame el celular ahí.

**Fernando:** Entonces, ven, eh... yo le había escrito a Alex para ver si se, él se juntaba ahora. Y me dijo... eh... tu tu tu tu tu tu tu tu tu... me dijo que le avisáramos. ¿Qué, qué hacemos? ¿Le decimos a Alex que se una y le planteamos estos temas o...

**Thony:** Bueno, sí, vamos a decirle, a ver que, pero que lo haga despacito para no... para poder entender la vaina. (Risas)

**Fernando:** Carajo fue el acelerado, ¿no?

**Thony:** Coño, sí.

**Fernando:** Dile que... coño, que está hablando con personas que están cercanos a la tercera edad.

**Thony:** Exacto. Ven acá, ¿cómo? (Risas) Él también es de la tercera edad, pero que le baje, que le baje la acelere. De la mediana edad, somos de la mediana edad, coño, no somos como él... Alex es más joven que nosotros, ¿no, coño?

**Fernando:** Sí, sí, sí, sí, sí. De acuerdo.

**Thony:** Entonces... eh... ¿Cuál es el... tú tienes el mail de Alex, o no?

**Fernando:** El... ¿cuál mail? ¿Le vamos a añadir, dices tú?

**Thony:** Sí.

**Fernando:** Co, pipo. Yo lo tengo aquí. Coño, sí, no, me echaron ahí una vaina, estoy ahorita discutiendo con la empresa el paquete nuevo.

**Thony:** ¿Te ofrecieron muy poco?

**Fernando:** Verga, una cagada, huevón. Pero bueno. Esa vaina de la tercera edad también huevón, ya no comienzan a uno a aplicar unos esos pajonazos.

**Thony:** Sí, huevón, no, te, te digo, es, es un tema... Es un tema jodido, huevón. O sea, yo, yo ahorita tengo un desconcierto de cuánto debería ganar yo, porque yo... yo sé que hay gente que gana mucha plata, yo ganaba bien. Pero coño, no sé cuánto es lo justo.

**Fernando:** Claro, esa es la vaina, huevón. Yo me puse a calcular una cuestión por ahí. Coño, y yo, verga, este sueldo... depende del... depende del país, huevón, en el, en Estados Unidos el sueldo no... de aquí no se compara con el de... con el de UAE, con el de Estados Unidos.

**Thony:** Ah, no, en Estados Unidos cualquier huevón gana más de 10.000 dólares mensuales, o sea. Cualquier huevón. Y, y sí, y ganar 20.000 no es una vaina tan, tan imposible.

**Fernando:** Tan loca.

**Thony:** Exacto, entonces coño yo... ciertamente estaba haciendo una cuestión ahí para una, una interview. Y... verga. Y todo depende del retorno también que uno traiga a la vaina, ¿no? Entonces... pero depende con quien uno esté hablando, si entiende ese tipo de, de valoraciones, ¿no?

**Fernando:** Sí.

**Thony:** Coño, mientras llega Alex, Fernando, ¿qué más crees tú que podemos hacer ahí con la parte industrial, huevón, ahí en Colombia? Porque tengo que mostrarte también una vainita ahí que hice en Google, pero para la vaina de... de la parte de marketing, huevón. De la vaina, es una, es una plataforma de marketing self-service. Entonces, entonces la vaina tiene una... tiene un modulito allí de, de que coño tú metes toda tu visión, tu... tu target, tu vaina y te hace todo el, el programa de trabajo. Y a parte de eso, puedes hacer tu webinar y toda tu, tu, tu mariquera ahí, ¿no? Entonces también, la idea es coño, comenzar a revender esa vaina, huevón, entonces quería ver si tú quieres echarle bola ahí a... a promover eso, y meterle un ojo también, ¿no? Y criticarlo un poco ahí para, para enriquecerla, porque José y yo pensamos lanzar esa vaina ahorita en... en un par de semanas, huevón.

**Fernando:** Sí. Mira, este, eh, disculpa que te interrumpa. Te acabo de copiar ahí en el WhatsApp el correo de Alex. Corporativo. El, el Gmail corporativo. Yo lo tengo aquí, es Ale, Ramón Pupo. A Sánchez, ajá, A Sánchez.

**Thony:** Sánchez Pupo, Ale Ramón Sánchez Pupo.

**Fernando:** No, pero el Ramón no...

**Thony:** Yo lo estoy... ya lo metí ya, pero el bicho no cae, no entra, huevón.

**Fernando:** ¿Por qué no entra?

**Thony:** No, no entra en la llamada, huevón. Déjame enviarle la invita... déjame enviarle la... ahí está. Déjame enviarle la invitación. Copy meeting link. Ponerlo acá. Este es el link.

**Fernando:** Okay, se lo... ah, se lo pasaste por, por WhatsApp. Sí. Okay.

**Thony:** Está bien, para alinearnos ahí rápidamente, para que esta reunión no vaya a ser una... una carrera ahí y volvamos a perder tiempo.

**Fernando:** Ah... espérate que...

**Thony:** Entonces vamos a preguntar, entonces al hombre le vamos a preguntar el workflow, que necesitamos una reunión de discovery, ¿no?

**Diego:** Y, y también los ingresos, porque el, él mandó un documento como de mercado potencial, pero pues él toma que todo que hay como un millón de motos en Venezuela, pero que todo ese millón es mercado potencial. Al inicio será llegarle a mucho menos de eso...

**Fernando:** Ah, no, no, pero él sí decía de eso él aspira a llegarle a un porcentaje, ¿no?

**Diego:** Mm, no veo eso.

**Fernando:** ¿No?

**Diego:** Él hablaba de un 25, 30% y...

**Thony:** 10%, él decía 10 mil motorizados por año.

**Fernando:** Sí.

**Diego:** Ah, porque él calculó que si se llega a 750 mil se puede potencial anual de 20 millones de dólares.

**Thony:** Exacto.

**Diego:** Y él tiene en cuenta que la tarifa básica son 17 dólares anuales.

*(Pausa)*

**Diego:** Y un 5% de cobertura empleada.

**Fernando:** Sí, el... exacto, son... los 17, la póliza normal, la de... esas son más simples, pero bueno...

**Diego:** 30% a 31 dólares...

*(Pausa)*

**Diego:** Entonces, en teoría, llegándole a 75 mil pueden ser 2 millones, según ese cálculo.

**Fernando:** ¿De motorizados?

**Diego:** No.

**Fernando:** ¿2 millones de dólares?

**Diego:** 2 millones de dólares con 75 mil motorizados.

*(Pausa)*

**Fernando:** ¿Él dice agregar 10 mil motorizados cada año, no?

**Diego:** Sí, o sea, se inicia con 10 mil, son...

*(Pausa)*

**Fernando:** Nosotros tenemos que diseñar una plataforma que maneje 10 mil... 10 mil motorizados. Inclusos o muchos más que esos. ¿Sabe cuántos motorizados hay en Colombia? En Colombia hay más o menos, creo que son, 8 millones de motorizados.

**Thony:** ¿Tú crees que también se pudiera vender en Colombia, entonces?

**Fernando:** No, lo que pasa es que aquí el sistema de salud funciona bastante bien... A diferencia de Venezuela. O sea, eso que él está ofreciendo allá, aquí eso no funcionaría. Porque tú, por obligaciones, aquí te tienen que recibir.

**Thony:** Ah, okay, okay.

**Fernando:** Funciona bastante bien. O sea... incluso ni te pueden recibir en una clínica privada. En Venezuela el seguro social... eso es un verguero, huevón. Law of the Jungle.

**Thony:** ¿Cómo es? A ver.

**Fernando:** Sí, sí... Mira, tú no pagas impuestos por estar en... ¿en Dubái, no?

**Thony:** No, no.

**Fernando:** No, eso es una ventaja huevón, a mí me quitan el 30%, huevón.

**Thony:** Pana, aquí un... aquí un CEO, pues, se puede conseguir una vaina buena por, como dices tú, unos 12, 15 mil dólares al mes. Empezando, pues.

**Fernando:** ¿De verdad?

**Thony:** Sí.

**Fernando:** No jodas, huevón, yo... Esta mierda, con esta devaluación de la moneda...

**Thony:** Coño, busca aquí chamo, busca aquí, pana. Esta guerra se va a terminar mañana si Dios quiere... O la semana que viene. Dentro de seis días... ya tengo seis días...

**Fernando:** ¿La guerra?

**Thony:** Sí.

**Fernando:** ¿Ha vuelto a ir en bombas?

**Thony:** Coño, no, pana, la vaina está gracias a Dios, está calmada, según Trump que le eliminaron el 85% de la capacidad militar a Irán.

**Fernando:** Ya a ese huevón le creo la mitad de lo que dice, huevón.

**Thony:** (Risas) De hecho es un CEO... CEO de Estados Unidos, huevón.

**Fernando:** Sí. Qué raro que...

**Thony:** Ah mira, Alex, te digo... Fernando, entonces, le vamos a preguntar el Discovery.

**Fernando:** ¿Discovery? Que acordemos los números del... del business, del... entender el negocio muy bien para ver, porque una cosa es que tú digas que puede vender dos millones de dólares, pero... ¿cuánto te va a quedar de eso? ¿el 5%, el 10, el 15? Cuando uno habla de una póliza que te cuesta 17 dólares... al... ¿Cuánto te puede quedar de ahí, huevón?

**Thony:** Claro, porque es un negocio de volumen. Esa plata entre clínicas, aseguradora y...

**Fernando:** Verga, sí. Y... y Rueda Seguro.

**Thony:** Y Rueda Seguro es la empresa, es la vaina, o ¿es el nombre del producto?

**Fernando:** Rueda Seguro es el producto, pero es la empresa también, ¿no? La que provee ese servicio. Él le vende este servicio a las aseguradoras, que son las que asumen el riesgo. Las que pagan los siniestros son las aseguradoras.

**Diego:** Claro, pero si igual... si una póliza cuesta 17 dólares... y la vendemos en 17 dólares... ¿Qué nos queda?

**Fernando:** Sí, pero esos 17 dólares es muy poquito, loco. O sea, 170.000 dólares al año...

**Diego:** Para Latinoamérica... Tonino.

**Fernando:** Coño, claro, pero son 170.000 dólares al año y ¿cómo tú pagas todos los gastos médicos? Ponte tú el 3% que se te accidenten de esos...

**Diego:** Sí.

**Thony:** Alex Sánchez, AS... llegó AS, el AS... (Risas) Acuérdense que los técnicos son ustedes, yo no...

**Fernando:** El AS... ¿Cómo está la vaina, Alex?

**Alex:** (Risas) Porque no quieres que te vea la... aquí está la cámara... Y aquí tengo un poco de computadoras aquí. Estoy en este cuarto, huevón.

*(Risas)*

**Fernando:** Coño, carajo, no jodas, eso parece un bro... un bróker de acciones.

**Alex:** Haciendo de todo ahí, está haciendo de todo ahí...

**Fernando:** (Risas) Sí...

**Alex:** La bolsa rebotó duro hoy, gracias a Dios.

**Thony:** Verga, chamo, sí, estaba... estaba fea la vaina, ¿no?

**Alex:** No, pero rebotó, rebotó hoy durísimo.

**Thony:** ¿Qué cosa? ¿A la bolsa que se cayó y?

**Alex:** No, rebotó, rebotó. Pero no le fue al que cayó, y bastante, porque Trump difirió por cinco... cinco días, no bombardea la verga... (Risas) No, y ese hijoeputa él si gana plata cuando cae y... él sabe que va a hablar, ¿no? Entonces él va... él compra cortos y compra largos, huevón. Y los asesores de él, los asesores de él ganan una poca plata, esos son los que más ganan cuando tienen conflictos de intereses...

**Fernando:** Mhm, tal cual.

**Alex:** (Risas) Cuéntame, mis panas.

**Fernando:** Mira, pana, este, no, queríamos, eh, varias cosas conversar contigo ahí. Una era, a ver, eh, Tony ha trabajado el tema de la base de datos, Diego ha trabajado también el tema de la aplicación y... y todo el asunto, sin embargo... eh, estábamos revisando y... y vamos a necesitar un tiempo, no sé si eres tú o alguien del equipo, que nos aclare dudas ya detalladas del proceso, para no estar inventándonos huevonadas que se vuelvan en pérdida de tiempo, ¿no? Digamos, del, del flujo, hay algunas preguntas que tenemos asociadas al negocio, y algunas preguntas asociadas a la parte del flujo del proceso. Entonces, llamémoslo de esa etapa, la etapa del Discovery, ¿mhm? Entonces, ¿con quién deberíamos manejar ese tema?

**Alex:** Bueno, yo tengo a William Porras y a Manuel, que están casualmente están en la sala mía trabajando el proyec... un proyecto ahí, y con ellos son los que debíamos trabajarlo, pero... pero podemos hablarlo ahorita y yo se los derivo. William, William es el que documenta todos los procesos y Manuel es el que calcula la parte de tarifa y tal, pero bueno, ellos son los que están trabajando conmigo también, ¿no? Que están metidos en el grupo.

**Fernando:** Oh... okay, exacto, entonces. Ese es un tema importante porque, a ver, ya Diego tiene un demo de la... del celular, ah... ya, ya hay bastantes vainitas, eso de capacitación del cliente, el que le toma la foto al escáner, todo esa vaina. Eso ya hay un... un demo, pero para que eso, realmente, poder salir a mostrarles una vaina bien montada y que se conecte... si nos gustaría eh... aclarar esas dudas. Entonces bueno, listo, vamos a, a cuadrar ahí un espacio con... con estos carajos.

**Alex:** Ya, déjame ponerlos ahí pa' decirle... Ven, ya que está la computadora aquí.

*(Pausa)*

**Alex:** William, ven acá, vamos a poner. Mira... este es el proyecto de Rueda Seguro. Aquí están conmigo. Aquí, aquí está William y aquí está Manuel. Hola, ¿qué tal? Hola, ¿cómo están?

**Thony/Fernando:** Hola, hola.

**Alex:** Tony, Fernando, amigos míos y... Diego es el hijo de él. Ellos, ellos están haciendo todo el trabajo de desarrollo de la plataforma y el... el dashboard de Rueda Seguro. Entonces, me preguntaban quién sabe toda la lógica de los procesos, ¿quién es el flujo? Y a William, él es el... el que maneja eso, en el detalle. Y el... el el desarrollo del proyecto lo... Manuel, Manuel y yo, y Leticia, fuimos los que lo hicimos, pero con nosotros es suficiente, hay suficiente información de lo que necesites.

**Fernando:** Sí, ahí para contarles rápidamente... ya se tiene una... un mock-up de... de la aplicación, un flujo, ya funciona la aplicación y tal, el asunto es que para avanzar bien, con paso firme, eh queremos entender bien las especificaciones de cuál es la expectativa de la conexión, por ejemplo con las empresas de seguro, con... con los brokers, con el oráculo... cómo se espera que funcione todo eso bien para poder meterle toda la lógica al, al software, ¿no? Este... aparte, hay unas preguntas de negocio para entender muy bien algunos aspectos del negocio para ver si eso tiene alguna implicación, ¿no? Este... y por supuesto también en el armado de la base de datos que está armando eh... Tony... validar que digamos, estamos disparando los tiros por donde son y... y, y, y, ¿cuál es la memoria que se requiere? ¿cuáles son los datos que realmente se necesitan para... para estar cumpliendo con todas las responsabilidades legales de SUDEASEG, del SENIAT, todo ese poco de vainas, no? Entonces por eso es que si queremos gastarle un tiempito para entender eso, ¿mhm?

**William/Manuel:** Okay.

**Fernando:** Dale, entonces...

**William/Manuel:** Perfecto, en el grupo estamos nosotros, están ellos dos, y bueno, cuadramos una reunión, pero, pero pregunta que tengan las podemos ir aclarando si tienen algo que quieran ahorita que preguntarnos que nosotros somos las personas que las vamos a contestar.

**Fernando:** Dale, no, no... si quieres, para hacerlo ahí como bien, si quieres buscamos un espacito, nos sentamos, puede ser hoy mismo y... y vamos chuleando punto por punto, ¿dale?

**William/Manuel:** Perfecto, perfecto. De todas formas... eh, hay alguna información adicional, el proveedor de servicios que se llama eh... Venemergencia, ya me pasó la siguiente cotización de... de él va a agarrar y va a estabilizar a los pacientes. Pero... pero... yo lo que quiero es que hagan las preguntas en función y yo se los voy diciendo para no llenarlos de cosas que no están encuadradas en lo que... en lo que ustedes necesitan. ¿Oíste? Porque, cómo, cómo funcionaría un poco el flujo... Eh, deberíamos nosotros tener una conexión vía API con la compañía de seguros que ellos tienen dos sistemas CORE, uno se llama Acsel y otro se llama Acsel... eh... Sirway y otra se llama Acsel. Y deberíamos tener una conexión vía API con el sistema del... proveedor, que es el servicio de atención médica o... o recogida en la calle o atención eh... domiciliaria o telemedicina. Que en ese caso es eh... eh... eh... Venemergencia. Venemergencia tiene seis centros propios y tiene unos locales, yo les voy a pasar la presentación de qué es Venemergencia... y qué es el que me va a dar el servicio de atención de la... de los accidentados. Okay. Entonces nosotros deberíamos conectarnos y, lo otro, nosotros tendríamos que enviar un mensaje a aquellas... a aquellas personas que están configuradas, ¿cómo se hace la suscripción? La suscripción como te dije, te voy a, yo creo que le mandé algo como se emitía, tomo la foto, tomo la placa, jalo los datos, me conecto por vía API con la aseguradora, invoco la póliza y ya eso, me pasa por una pasarela de pago, a la pasarela de pago, en las modalidades que hay pago móvil, pago directo, lo que sea. Hago... cuando eso está cobrado, ya los tres actores, la compañía de seguros, el dashboard que está haciendo eh... Tony y el... el evento de emergencia debería tener... tener la misma información y el usuario... debería haberle llegado a su teléfono o... un código QR para que él pueda escanear, vía PDF la póliza, para que él tenga garantía de que hizo el pago y que tiene la... la cobertura. Porque la póliza se emite hasta con un carnet, porque los... los cobres de seguridad del estado aquí los paran y ellos tienen que mostrarles el carnet de la póliza para que la póliza esté vigente pues. Entonces...

**Fernando:** ¿La de responsabilidad civil?

**Alex:** ¿Cómo?

**Fernando:** Sí, la de responsabilidad civil.

**Alex:** Sí, responsabilidad civil. Exacto.

**Fernando:** Okay, okay.

**Diego:** Y, y esa aplicación... eh... la idea es que esté siempre corriendo en segundo plano y... y con los sensores del dispositivo vaya... tomando los datos, ¿en caso de un choque, cierto?

**Alex:** Sí, debería ir corriendo en segundo plano y no debería ir guardando tanta memoria... debería guardar una memoria temporal de... de 10, 15 minutos porque si después de eso si un accidente pasa, para no llenarnos de tanta información. Más adelante si queremos medir conducta y otras cosas, es otro tema. Pero ahorita lo que necesito es que me guarde el tiempo del accidente, 5 minutos atrás o 5 minutos adelante. Básicamente eso, lo demás no... no es relevante para tomar una decisión de pago, ¿por qué? Nosotros queremos... hay unos seguros que se llaman paramétricos, queremos que dada una circunstancia de la regla de negocio, se cayó, iba a 70, se dio un golpe, no hizo el dispositivo... eh... yo genero un... no sé si es un smart contract o algo automatizado por la pasarela de APIS, donde yo le indemnizo una parte que él necesita para comprar los insumos o... o lo atiende directamente. Hay dos mecanismos ahí, si el tipo compra una póliza que es barata... porque yo creo que hay tres niveles, uno que es básico, uno medio y otro plus... La barata te indemnizo y ya. Si si te mataste o te... o no te alcanzó, estás jodido. Pero en la póliza... eh... plus te llevo a un centro asistencial. Y en la póliza super plus, por decirlo así... eh... te acompaño hasta el final de tu recuperación. Es como pa... pa decirte bueno, si tú te caíste y... y... y tienes la póliza de 500 dólares y... y el oráculo dice iba a una velocidad de 60 kilómetros, te caíste en un territorio, en una cosa que está pa... bien. El dinero funcionó, yo te mando un pago móvil, te pagué y salí del cuento. Si tú compraste la más... la más robusta... yo le mando un mensaje a la, a Venemergencia, Venemergencia se entera que te pasó, y te dice "vente pa' acá papito que aquí te vamos a poner bonito, te vamos a volver a poner los pies donde están, en la madre te vamos a curar". Y en el tercer caso... eh... pasa por ese mecanismo y después me encargo de ti en la recuperación. Más o menos ese sería el diseño de los tres productos. Para agarrar esos amplios... esos tres niveles como lo estamos conceptualizando.

**Fernando:** Sí. ¿Y qué era lo que costaba? ¿El básico era el de 17 dólares?

**Alex:** Sí, ese 17 dólares tiene nomás RCV, no tiene cobertura de salud. La cobertura de salud ya Manduel ha tarifado y... y supónte que cueste 100 dólares al año, son, son 10 dólares más mensual, terminará costando la póliza 130 dólares, los 17 de la RCV más los 100 de eso. La otra sería... los 17 del RCV que es el, es un monto legal, más 200, más 150\. Él tiene la tarifa montada, de acuerdo a las coberturas. Pero lo que estábamos ahora era esperando eh... el proveedor de atención de salud porque él tenía que darme un precio capitado. ¿Qué significa eso? En seguro se maneja que, por cada usuario que yo tenga yo le pago un fee a él, no es que pago la cobertura del, del caso. Me va a cobrar 2.71 por cada... eh... motorizado que... que yo tenga en el sistema. Entonces por eso es que la información de la cantidad de motorizados que están vigentes es importante, porque yo pago sobre eso. Claro. Es 2.71, por eso lo vamos a negociar, ese es el monto que nos dio inicialmente, pues.

**Thony:** Ahora una pregunta Alex, entonces, supónte tú que ya tenemos, estamos trayendo la data del, de la aplicación, la tenemos ya en el dashboard, te... todo está montado y tal. Tenemos la conexión con el, Vene- Venesasistencia, y tenemos la compañía, con la compañía de seguro. ¿La compañía de seguros es la compañía tuya o es una compañía de terceros?

**Alex:** Van a hacer diferentes compañías. Ese es un servicio que le vamos a vender, porque la póliza RCV la venden diferentes compañías. Nosotros lo que le vamos a vender un servicio pegada a la póliza de RCV. Claro, la compañía de nosotros que queremos tener no la tenemos todavía lista. De hecho estamos trabajando en eso, eso va a tardar un año en que nos la aprueben. Pero mientras eso pasa, probamos el modelo con, con Estar Seguro, con Mercantil, con cualquier compañía que nos compre el servicio. Oíste, inicialmente vamos a... vamos a ser un prestador de servicio para las compañías de seguros. Y como estamos habilitados como Insurtech, no tenemos problemas regulatorios. Nosotros podemos hacerlo bajo la figura de Insurtech porque esa sí la tenemos aprobada.

**Diego:** La...

**Alex:** ¿Cómo? Disculpa.

**Diego:** No, eh... ¿Qué pena? En la app va a salir entonces... ¿Ese precio está regulado, no? ¿Es el mismo para cada aseguradora o cada aseguradora cobra lo que quiera?

**Alex:** No, está regulada la cobertura básica de RCV. Es un tema legal, pero en exceso de eso cada aseguradora va a cobrar de acuerdo al diseño del producto que nosotros le planteemos. A lo mejor Seguros Caracas, que tiene los motorizados que tienen más plata aquí... terminan cobrando, eh... el producto va a ser con la cobertura más plus. Eh... Seguros Universitas, que tiene una base de motorizados más chiquiticos... la cobertura más... entonces es... esos tres productos vamos, de acuerdo al servicio que requieran y a la propuesta de valor de cada cobertura se lo vamos a vender a la compañía. Pero básicamente vamos... nosotros vamos a ser proveedores de tecnología para la compañía de seguros, mientras tenemos nuestra propia compañía que eso nos va a llevar un año.

**Diego:** Pero entonces en la aplicación, ¿el usuario es el que decide con qué aseguradora se va o simplemente compra algo genérico, básico, y, y nosotros...?

**Alex:** No, nosotros en la aplicación de Aceta Capital, que es la Insurtech, vamos a tener las opciones. Nosotros vamos a poner en esa plataforma, las compañías que nosotros consideramos que... que pueden hacer. El usuario puede definir con qué compañía lo... lo hace, pero... como eso se vende a través de un corredor de seguros, hay muchos corredores de seguros que van a vender la compañía donde ellos hacen negocio, ¿pues? Claro. Ellos pueden comprar directamente por el portal. Pero normalmente estas pólizas se venden a través de una compañía de seguros, de un, de un corretaje, de un canal alternativo. No es que na- nadie sale a comprar un seguro solo en este país. Con ese poco de... de buitres que hay aquí en este país buscando quien asegurar. ¿Ok?

**Diego:** Claro, entonces ellos entran por ejemplo a... a Seguros Caracas... compran la póliza por ahí y lo único que hacen es después inscribirse a la...

**Alex:** No, ellos entran a la plataforma de nosotros y esa plataforma los manda para Seguros Caracas. Ellos... porque nosotros tenemos que quedarnos con la data, porque ese cliente es de nosotros, a pesar de que... le... Seguros Caracas no es el servicio de cobertura. Si ellos entran directo a Seguros Caracas perdemos el, el control del cliente nosotros.

**Diego:** Pero entonces la plataforma de pagos... ¿Se queda en, en el nuestro, no?

**Alex:** Sí, la pasarela de pagos es de nosotros y está pegada a la aplicación. Nosotros recaudamos el cien por ciento de la póliza y le liquidamos a la aseguradora su parte.

**Diego:** Ah, entiendo.

**Fernando:** O sea que básicamente tú cobras los 130 dólares, le pasas los 17 de la responsabilidad civil a la aseguradora y ustedes se quedan con el diferencial para cubrir los servicios médicos, la tecnología y el margen.

**Alex:** Es correcto, Fernando. Así es como funciona el modelo, nosotros administramos esa siniestralidad. Y al tener la telemetría y los datos, bajamos el riesgo.

**Thony:** Claro, claro. Está, está bien pensado el negocio, huevón.

**Alex:** Bueno mis panas, yo me tengo que saltar a otra llamada que ya me están esperando. Pero entonces cuadren con William y con Manuel para ver el detalle de los flujos, las APIs y la base de datos que está haciendo Thony.

**Fernando:** Dale Alex, perfecto. Nosotros los contactamos por el grupo y agendamos eso.

**Alex:** Buenísimo. Un abrazo para todos, cuídense.

**Thony:** Un abrazo, hermano. Saludos.

**Diego:** Chao, gracias.

**Fernando:** Chao, chao.