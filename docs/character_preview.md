# Vista previa del personaje (menú)

La vista previa **3D está integrada en el menú principal**: al pulsar **Personalizar personaje** se muestra un panel con:

- Pestaña **Identidad**: género, raza, ropa (listas).
- Pestaña **Cuerpo**: sliders de proporciones y tonos (estilo ARK).
- **SubViewport** a la derecha con el modelo procedural y **click derecho** para orbitar la cámara.

El modelo actual son **primitivas estilo chibi** (marcador de posición). Para acercarse a un acabado tipo **figura 3D anime** (como referencias de juegos con personajes “toy/chibi” de alta calidad) hace falta **importar un GLTF/GLB** hecho en Blender u otro DCC, con materiales y rig; el código ya concentra la lógica en `ProceduralHumanoid` y `CharacterDraft` para poder sustituir mallas más adelante.
