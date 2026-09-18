# SDD Music

Aplicación Flutter para crear playlists en el dispositivo, escanear archivos de
audio en Documentos, Descargas y Música, y buscar/descargar el audio MP3 de
vídeos de YouTube.

Los datos de playlists y descargas se guardan en un archivo JSON dentro de la
memoria interna de la aplicación; no se utiliza ninguna base de datos.

El menú inferior tiene cuatro áreas derivadas de los requisitos: Playlists,
Descargar, Recomendaciones y Visor de YouTube. La asignación de una canción a
una playlist se hace explícitamente desde el detalle de la playlist.

El panel "Audio y efectos", en el botón contiguo al de recargar, regula los
valores de reproducción (volumen, velocidad y tono) y aplica efectos de sonido
(ecualizador de graves, voz y agudos, y realzador de sonoridad). El requisito no
concreta ni los valores ni los efectos, así que se usan los que ya ofrece
`just_audio`, sin dependencias ni recursos nuevos: los efectos de audio de ese
paquete solo existen en Android y, en el resto de plataformas, el panel ofrece
únicamente los valores. Los ajustes se mantienen mientras la aplicación está
abierta; no se guardan en el dispositivo porque el requisito no pide
persistencia.

# Musikapp_sdd
