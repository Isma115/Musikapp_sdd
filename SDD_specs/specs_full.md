# Specs

## Tecnologías a utilizar
- Estado: Implementada
- Categoría: Tecnologías
- Color: Azul

Aplicación móvil construida en Flutter, Dart

## Ventana principal
- Estado: Implementada
- Categoría: Vistas
- Color: Rojo

Vista de lista de Playlists: La vista con la lista de playlists, arriba de la vista aparecerá un botón "+ Añadir Playlist" y debajo de este estarán todas las playlists creadas

## Navegación entre vistas
- Estado: Implementada
- Categoría: Navegador de vistas
- Color: Naranja

Estará ubicado como menú inferior horizontal de la aplicación, con 4 botones disponibles de navegación

## Almacenamiento de datos
- Estado: Implementada
- Categoría: Almacenamiento
- Color: Verde

En la memoria interna del dispositivo del usuario, no se almacenará nada en ninguna base de datos, todo en el teléfono del usuario

## Escaneo de música
- Estado: Implementada
- Categoría: Funcionamiento
- Color: Rojo

Cada vez que el usuario entre en la aplicación, se escanearán las principales carpetas del usuario: Documentos, Descargas, Música

Solamente esas carpetas en las que se buscará la música disponible y se agregará a su playlist determinada por el usuario

## Añadir música a Playlist
- Estado: Implementada
- Categoría: Funcionamiento
- Color: Rojo

Dentro de una Playlist, de forma similar a la vista de Playlists, habrá un botón "+ Añadir canción" que añadirá una canción dentro de la playlist, esta vista tendrá el mismo aspecto visual o similar que la vista principal de las Playlists

## Vista Descargar de YouTube
- Estado: Implementada
- Categoría: Vistas
- Color: Rojo

Otra vista accesible desde el menú de navegación inferior
Esta ventana permitirá descargar un audio de youtube mp3 a través de un vídeo

Aparecerá una barra de búsqueda en la parte superior de la vista, y una vez se introduzca un término de búsqueda, se listará en una lista todos los vídeos resultantes de la búsqueda.

Al lado de cada uno de los vídeos listados, habrá en el lado izquierdo de estos, un botón de descargar, una vez se pulse ese botón se comenzará con el proceso de descargar del audio. La descarga comenzará y continuará mientras el usuario tenga la app activa. Como resultado el audio se guardará en la carpeta del usuario de Descargas

## Vista visor de Youtube
- Estado: Implementada
- Categoría: Vistas
- Color: Rojo

Todo lo que tiene que hacer esta nueva vista es simplemente permitir al usuario buscar videos en youtube, a través de un campo de búsqueda superior y una vez hecha la búsqueda le aparecerán enlaces listados a youtube con esos vídeos

Visualmente será similar a la vista de descargar de youtube

## Vista Recomendaciones
- Estado: Implementada
- Categoría: Vistas
- Color: Rojo

Una vista nueva (la tercera del menú de navegación)

Van a aparecer solamente una lista con las canciones recomendadas, en base al patrón de escucha que tenga el usuario. Se utilizará un algoritmo de recomendación sencillo de puntuación de canciones

## Paleta de colores
- Estado: Implementada
- Categoría: Diseño
- Color: Amarillo

La paleta de colores debe ser modo oscuro tonos azules, morados y violetas

## Formas de los componentes
- Estado: Implementada
- Categoría: Diseño
- Color: Amarillo

No quiero bordes redondeados, quiero que los componentes sean rectangulares, botones, elementos, etc

## Reproducción en segundo plano
- Estado: Implementada
- Categoría: Funcionamiento
- Color: Rojo

La música, audio, o lo que se esté reproduciendo tiene que seguir reproduciéndose mientras la app esté en segundo plano o aunque el teléfono esté con la pantalla apagada

## Robusted de descarga
- Estado: Implementada
- Categoría: Funcional
- Color: Rojo

Haz mucho más robusta la descarga de música en la vista de Descargar, tiene que haber opciones por si un método de descarga falla

## Ventana de Reproducción
- Estado: Implementada
- Categoría: Funcional
- Color: Rojo

Se requiere de una vista nueva que tenga los controles de reproducción de una canción determinada, esta vista podrá expandirse y contraerse, para que mientras se reproduce la canción se pueda utilizar el resto de vistas de la aplicación, tendrá botón de pausa y siguiente canción o anterior

En la vista de la música, ya sea dentro de una playlist o de la vista de Recomendaciones, se podrá reproducir una canción dandole a un botón o pulsando sobre la propia canción

## Fix: Tamaño de las canciones en la lista
- Estado: Implementada
- Categoría: Fix
- Color: Rojo

Al entrar en una playlist, el tamaño de los elementos de la lista de canciones es muy grande en altura, cuanto más grande es el título de una canción más grande es, haz que tenga un tamaño fijo no tan alto

## Divisón de responsabilidades
- Estado: Implementada
- Categoría: Rendimiento
- Color: Índigo

El código de la aplicación debe estar separado y dividido correctamente por funcionalidades en lugar de tener ficheros de código demasiado grandes que abarquen demasiado: división por vistas, funcionamiento, utils, etc

## Mejora de descarga
- Estado: Implementada
- Categoría: Funcional
- Color: Rojo

La descarga de nueva música tarda muchísimo o no funciona correctamente, vídeos de 1 minuto ha conseguido descargar, pero la mayoría no lo consigue.

Investiga adecuadamente como solucionar esto e implementar una solución mejorada

## Recarga de canciones
- Estado: Implementada
- Categoría: Funcional
- Color: Rojo

El escaneo se ejecutará manualmente, cada vez que le de al botón de recargar

## Mensaje de Error en descarga
- Estado: Implementada
- Categoría: Funcional
- Color: Rojo

Si la descarga de un audio falla, al lado del botón "Opciones" que aparece en el toast emergente, estará también la opción "Mostrar" el cual mostrará una caja de texto al frente con todo el mensaje de error completo, con botón Aceptar

## Progreso de descarga
- Estado: Implementada
- Categoría: Diseño
- Color: Amarillo

Si una canción consigue comenzar a ser descargada, tiene que ser posible ver una barra de progreso de descarga, la cual será el propio indicador de círculo con un porcentaje, (primero aparece un círculo indicando que se está descargando, pero no indica el progreso de descarga) implementalo de esa manera

## Fix: Audio interrumpido al ejecutar en segundo plano
- Estado: Activa
- Categoría: Fix
- Color: Rojo

Ocurre un error al momento de que el audio se reproduzca en segundo plano, ya sea con la app ejecutándose en segundo plano o con el teléfono con la pantalla apagada, pasado un tiempo de reproducción, la app se cierra automáticamente, comprueba que puede estar pasando y dale una solución permanente

## Fix: Toasts demasiado largos
- Estado: Activa
- Categoría: Fix
- Color: Rojo

Los mensajes de Toast que salen en la aplicación tardan muchísimo en cerrarse o nunca se cierran automáticamente, corrígelo

## Icono de aplicación
- Estado: Activa
- Categoría: Diseño
- Color: Amarillo

El icono principal de la aplicación debe ser original y atractivo, pero simple, impleméntalo para que aparezca el icono al utilizar la app

# BBDD

No hay tablas definidas.

# UI

No hay referencias de interfaz definidas.

# Recursos

La carpeta `specs_resources` no contiene archivos.
