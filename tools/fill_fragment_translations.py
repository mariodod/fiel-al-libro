#!/usr/bin/env python3
"""Fill msgstr for all fragment keys in all 6 PO files, and remove dead .01 duplicate keys.

For each fragment (ch15-ch50), the game uses keys WITHOUT the .01 suffix:
  ui.book.{base}.name
  ui.face.{base}.reality.desc
  ui.face.{base}.reality.tell
  ui.face.{base}.book.desc
  ui.face.{base}.book.tell

Spanish translations go into es.po; English fallback goes into en/fr/de/it/pt_BR.
The .01-suffixed duplicates (dead keys, never referenced by any .tres) are removed.
"""

from pathlib import Path
import re

LOCALE_DIR = Path("locale")
PO_FILES = ["en.po", "es.po", "fr.po", "de.po", "it.po", "pt_BR.po"]

FRAGMENT_IDS = [
    "bk.ch15.muerto_camino",
    "bk.ch16.barca_encantada",
    "bk.ch17.hombre_muerto",
    "bk.ch18.libros_quemados",
    "bk.ch20.dulcinea_encantada",
    "bk.ch22.duelo_luz_luna",
    "bk.ch23.montesinos",
    "bk.ch24.altisidora",
    "bk.ch25.conde_altisidora",
    "bk.ch26.melisendra",
    "bk.ch27.molinos_llenadores",
    "bk.ch28.encantada",
    "bk.ch29.penitentes",
    "bk.ch30.leones_carro",
    "bk.ch31.cueva_hermoso",
    "bk.ch32.ventura_duque",
    "bk.ch33.leones_reales",
    "bk.ch34.encantamiento",
    "bk.ch35.caballero_blanco",
    "bk.ch36.cuidado_sancho",
    "bk.ch37.encantamiento_duquesa",
    "bk.ch38.clavileño",
    "bk.ch39.sancho_gobernador",
    "bk.ch40.entierro_rico",
    "bk.ch41.oviedo",
    "bk.ch42.maestro_pedro",
    "bk.ch43.caso_penal",
    "bk.ch44.duelo_evitados",
    "bk.ch45.encantamiento_sancho",
    "bk.ch46.leones_corte",
    "bk.ch47.despedida",
    "bk.ch48.regreso_pueblo",
    "bk.ch50.impertinente",
]

# Spanish translations: frag_id -> {name, reality.desc, reality.tell, book.desc, book.tell}
SP = {
    "bk.ch15.muerto_camino": {
        "name": "El Hombre Muerto",
        "reality.desc": "Un hombre yace muerto junto al camino, vestido de blanco.",
        "reality.tell": "Las heridas en su cuello no son de esta época.",
        "book.desc": "Un libro abierto descansa sobre el pecho del hombre muerto.",
        "book.tell": "Las páginas están escritas con tinta de color sangre.",
    },
    "bk.ch16.barca_encantada": {
        "name": "La Barca Encantada",
        "reality.desc": "Una barca pequeña está atada a la orilla del río.",
        "reality.tell": "La barca no tiene remos, pero el agua la mueve.",
        "book.desc": "Un bote encantado flota solo sobre el río, sin tripulación.",
        "book.tell": "Las aguas del río arden con fuego azul bajo la luz de la luna.",
    },
    "bk.ch17.hombre_muerto": {
        "name": "El Hombre Muerto del Camino",
        "reality.desc": "Un cadáver yace sobre la tierra, vestido con ropas de caballero.",
        "reality.tell": "El hombre no tiene heridas visibles, pero está claramente muerto.",
        "book.desc": "Un libro yace sobre el pecho del hombre, sus páginas parpadean con luz.",
        "book.tell": "El libro lee los pensamientos de quien lo mira.",
    },
    "bk.ch18.libros_quemados": {
        "name": "Los Libros Quemados",
        "reality.desc": "Una pila de libros arde en una hoguera al borde del camino.",
        "reality.tell": "Las llamas son de un color anormal, de un verde enfermizo.",
        "book.desc": "Un libro intacto flota sobre las llamas, sin quemarse.",
        "book.tell": "El fuego no puede destruir el conocimiento contenido en sus páginas.",
    },
    "bk.ch20.dulcinea_encantada": {
        "name": "Dulcinea Encantada",
        "reality.desc": "Una muchacha campesina se sienta en una roca, mirando al horizonte.",
        "reality.tell": "Sus ojos brillan con un brillo que no es natural.",
        "book.desc": "Una dama de noble porte, vestida de seda y joyas, mira desde un balcón.",
        "book.tell": "Su belleza es eterna, pero nadie puede recordarla después de mirarla.",
    },
    "bk.ch22.duelo_luz_luna": {
        "name": "El Duelo a la Luz de la Luna",
        "reality.desc": "Dos hombres se enfrentan en el claro del bosque bajo la luna llena.",
        "reality.tell": "Las sombras de los combatientes se mueven independientemente de ellos.",
        "book.desc": "Dos caballeros luchan bajo la luz de la luna plateada, sus espadas brillan.",
        "book.tell": "La luna ilumina solo a los duelistas, dejando todo lo demás en sombra absoluta.",
    },
    "bk.ch23.montesinos": {
        "name": "La Cueva de Montesinos",
        "reality.desc": "La entrada de una cueva oscura se abre en la ladera de la montaña.",
        "reality.tell": "El aire que sale de la cueva huele a incienso y sudor.",
        "book.desc": "Una cueva encantada brilla con luz mágica desde su interior.",
        "book.tell": "Quien entra en la cueva regresa cambiado, hablando de cosas imposibles.",
    },
    "bk.ch24.altisidora": {
        "name": "Altisidora",
        "reality.desc": "Una doncella joven canta junto a una fuente, rodeada de pájaros.",
        "reality.tell": "Su canto provoca que las flores se marchiten al oírlo.",
        "book.desc": "Una doncella de noble cuna canta una canción de amor prohibido.",
        "book.tell": "Quien oiga su canción se enamorará perdidamente y nunca podrá olvidarla.",
    },
    "bk.ch25.conde_altisidora": {
        "name": "El Conde Altisidora",
        "reality.desc": "Un conde de aspecto noble recibe visitas en su castillo.",
        "reality.tell": "Las sombras en su castillo se mueven cuando él no está mirando.",
        "book.desc": "Un conde vestido con ropas de fiesta organiza un banquete eterno.",
        "book.tell": "Los invitados del banquete nunca envejecen ni mueren.",
    },
    "bk.ch26.melisendra": {
        "name": "Melisendra",
        "reality.desc": "Una mujer canta junto a un escenario de títeres en la plaza del pueblo.",
        "reality.tell": "Los títeres se mueven solos cuando ella no los toca.",
        "book.desc": "Una hechicera dirige un teatro de sombras donde los personajes cobran vida.",
        "book.tell": "Las sombras del teatro predicen el futuro de quien las observa.",
    },
    "bk.ch27.molinos_llenadores": {
        "name": "Los Molinos Llenadores",
        "reality.desc": "Varios molinos de viento giran lentamente en la llanura.",
        "reality.tell": "Los molinos giran incluso cuando no hay viento.",
        "book.desc": "Molinos llenadores de vino y aceite, trabajando sin cesar bajo la luna.",
        "book.tell": "Los molinos muelen no grano, sino los sueños de quienes los ven.",
    },
    "bk.ch28.encantada": {
        "name": "La Encantada",
        "reality.desc": "Una dama se sienta en el balcón de un castillo, esperando.",
        "reality.tell": "Su rostro no refleja la luz de la luna.",
        "book.desc": "Una dama encantada espera en un torreón, rodeada de encantamientos.",
        "book.tell": "Solo quien rompa el hechizo podrá ver su verdadero rostro.",
    },
    "bk.ch29.penitentes": {
        "name": "Los Penitentes",
        "reality.desc": "Un grupo de penitentes de blanco camina por el camino al amanecer.",
        "reality.tell": "Sus rostros están cubiertos, y no dejan huella en el polvo.",
        "book.desc": "Un grupo de penitentes lleva capirotes blancos y cruces de fuego.",
        "book.tell": "Quien se una a los penitentes nunca podrá salir del camino.",
    },
    "bk.ch30.leones_carro": {
        "name": "Los Leones del Carro",
        "reality.desc": "Un carro tirado por leones cruza el camino, guiado por un cuidador.",
        "reality.tell": "Los leones no tienen collares ni cadenas, pero no atacan.",
        "book.desc": "Leones domados por un mago viajan en un carro encantado.",
        "book.tell": "Los leones son guardianes de un secreto que nadie debe conocer.",
    },
    "bk.ch31.cueva_hermoso": {
        "name": "La Cueva de Hermoso",
        "reality.desc": "Una cueva oscura se oculta tras una cascada en la montaña.",
        "reality.tell": "El agua de la cascada fluye hacia arriba, no hacia abajo.",
        "book.desc": "Una cueva encantada alberga a un ermitaño que sabe el futuro.",
        "book.tell": "El ermitaño conoce el destino de quien entra, pero no puede cambiarlo.",
    },
    "bk.ch32.ventura_duque": {
        "name": "El Castillo del Duque",
        "reality.desc": "Un castillo imponente se alza en la cima de la colina.",
        "reality.tell": "Las torres del castillo cambian de posición cuando nadie mira.",
        "book.desc": "El castillo del Duque está lleno de maravillas y encantamientos.",
        "book.tell": "Quien entra al castillo del Duque no puede salir sin pagar un precio.",
    },
    "bk.ch33.leones_reales": {
        "name": "Los Leones Reales",
        "reality.desc": "Un grupo de leones está enjaulado en el castillo del Duque.",
        "reality.tell": "Los leones miran con ojos que no parpadean nunca.",
        "book.desc": "Leones mágicos custodian el tesoro del Duque en su jaula encantada.",
        "book.tell": "Quien robe a los leones será devorado por su propia sombra.",
    },
    "bk.ch34.encantamiento": {
        "name": "El Encantamiento",
        "reality.desc": "Un castillo está rodeado de niebla que no se disipa con el sol.",
        "reality.tell": "Las torres del castillo cambian de lugar cada vez que se miran.",
        "book.desc": "Un castillo encantado está protegido por hechizos imposibles de romper.",
        "book.tell": "Solo quien rompa el hechizo podrá entrar al castillo encantado.",
    },
    "bk.ch35.caballero_blanco": {
        "name": "El Caballero de la Blanca Luna",
        "reality.desc": "Un caballero rival derrota a Quixote en combate y lo envía a casa.",
        "reality.tell": "La armadura del caballero no tiene grietas ni abolladuras.",
        "book.desc": "Un caballero rival lucha con una espada de luz.",
        "book.tell": "Quien venza al Caballero de la Blanca Luna recibirá una maldición eterna.",
    },
    "bk.ch36.cuidado_sancho": {
        "name": "El Cuidado de Sancho",
        "reality.desc": "Sancho cuida de Quixote mientras duerme bajo un árbol.",
        "reality.tell": "Sancho no puede dormir mientras Quixote esté herido.",
        "book.desc": "Sancho cuida de Quixote mientras duerme bajo un árbol encantado.",
        "book.tell": "El sueño de Quixote está protegido por hechizos antiguos.",
    },
    "bk.ch37.encantamiento_duquesa": {
        "name": "El Encantamiento de la Duquesa",
        "reality.desc": "La Duquesa finge estar encantada para engañar a Sancho.",
        "reality.tell": "La Duquesa no está realmente encantada, pero lo finge bien.",
        "book.desc": "La Duquesa está realmente encantada y necesita ayuda para romperlo.",
        "book.tell": "Solo quien pueda desencantar a la Duquesa podrá obtener su recompensa.",
    },
    "bk.ch38.clavileño": {
        "name": "Clavileño",
        "reality.desc": "Un caballo de madera está listo para volar en el patio del castillo.",
        "reality.tell": "El caballo de madera no tiene alas, pero puede volar.",
        "book.desc": "Clavileño, el caballo de madera encantado, vuela por los cielos nocturnos.",
        "book.tell": "Quien monte en Clavileño ve cosas que ningún mortal ha visto.",
    },
    "bk.ch39.sancho_gobernador": {
        "name": "Sancho Gobernador",
        "reality.desc": "Sancho gobierna la ínsula de Barataria con sabiduría.",
        "reality.tell": "Los ciudadanos de la ínsula respetan a Sancho más que a cualquier gobernador.",
        "book.desc": "Sancho gobierna una ínsula encantada donde las leyes de la física no aplican.",
        "book.tell": "Quien gobierne la ínsula encantada perderá la cordura en menos de un mes.",
    },
    "bk.ch40.entierro_rico": {
        "name": "El Entierro Rico",
        "reality.desc": "Un entierro rico pasa por el camino con luctuosos y músicos.",
        "reality.tell": "El ataúd es demasiado ligero para contener un cuerpo adulto.",
        "book.desc": "Un entierro encantado lleva un ataúd que no contiene cuerpo alguno.",
        "book.tell": "Quien abra el ataúd encontrará su propia muerte escrita en su interior.",
    },
    "bk.ch41.oviedo": {
        "name": "Oviedo",
        "reality.desc": "Un bachiller de Oviedo discute literatura con Quixote.",
        "reality.tell": "El bachiller no sabe leer ni escribir, pero discute de literatura.",
        "book.desc": "Un libro falso de aventuras cuenta hazañas que nunca ocurrieron.",
        "book.tell": "Quien lea el libro falso se convierte en personaje de sus páginas.",
    },
    "bk.ch42.maestro_pedro": {
        "name": "Maestro Pedro",
        "reality.desc": "Maestro Pedro presenta su retablo de títeres en la plaza del pueblo.",
        "reality.tell": "Los títeres del retablo se mueven solos cuando Maestro Pedro no los toca.",
        "book.desc": "El retablo de Maestro Pedro muestra escenas que aún no han ocurrido.",
        "book.tell": "Quien vea el retablo ve su propio futuro en las escenas.",
    },
    "bk.ch43.caso_penal": {
        "name": "El Caso Penal",
        "reality.desc": "Un caso penal es llevado ante el Duque.",
        "reality.tell": "El acusado es inocente, pero todos creen que es culpable.",
        "book.desc": "Un criminal encantado es juzgado por crímenes que no cometió.",
        "book.tell": "Quien condene al criminal encantado será condenado a su vez.",
    },
    "bk.ch44.duelo_evitados": {
        "name": "El Duelo Evitado",
        "reality.desc": "Dos caballeros se enfrentan en un duelo que nadie quiere ver.",
        "reality.tell": "Ambos caballeros tienen miedo de luchar, pero no quieren retroceder.",
        "book.desc": "Dos caballeros encantados duelen eternamente sin herirse nunca.",
        "book.tell": "Quien termine el duelo será condenado a luchar eternamente.",
    },
    "bk.ch45.encantamiento_sancho": {
        "name": "Sancho Encantado",
        "reality.desc": "Sancho está encantado y cree ser alguien que no es.",
        "reality.tell": "Sancho no recuerda quién es realmente, pero actúa como otro.",
        "book.desc": "Sancho está encantado por una bruja y cree ser un noble.",
        "book.tell": "Quien desencante a Sancho descubrirá su verdadera identidad.",
    },
    "bk.ch46.leones_corte": {
        "name": "Los Leones de la Corte",
        "reality.desc": "Leones reales están enjaulados en la corte del Duque.",
        "reality.tell": "Los leones no rugen, pero su mirada helada detiene a cualquiera.",
        "book.desc": "Leones mágicos custodian el tesoro del Duque en su jaula encantada.",
        "book.tell": "Quien robe a los leones será devorado por su propia sombra.",
    },
    "bk.ch47.despedida": {
        "name": "La Despedida",
        "reality.desc": "Quixote y Sancho se despiden del Duque y la Duquesa.",
        "reality.tell": "El Duque y la Duquesa lloran al despedir a Quixote y Sancho.",
        "book.desc": "Una despedida encantada en el castillo del Duque, llena de lágrimas mágicas.",
        "book.tell": "Quien presencie la despedida lo recordará para siempre.",
    },
    "bk.ch48.regreso_pueblo": {
        "name": "El Regreso al Pueblo",
        "reality.desc": "Quixote y Sancho regresan a su pueblo después de muchas aventuras.",
        "reality.tell": "El pueblo no los reconoce, pero ellos recuerdan cada detalle.",
        "book.desc": "Quixote y Sancho regresan a un pueblo encantado que no recuerda su nombre.",
        "book.tell": "Quien regrese al pueblo encantado no podrá salir de él.",
    },
    "bk.ch50.impertinente": {
        "name": "El Curioso Impertinente",
        "reality.desc": "Un hombre cuenta la historia del Curioso Impertinente en la posada.",
        "reality.tell": "La historia del Curioso Impertinente es demasiado real para ser inventada.",
        "book.desc": "La historia del Curioso Impertinente se cuenta en un libro encantado.",
        "book.tell": "Quien lea la historia del Impertinente se convierte en el Impertinente.",
    },
}

# English fallback translations
EN = {
    "bk.ch15.muerto_camino": {
        "name": "The Dead Man",
        "reality.desc": "A dead man lies by the roadside, dressed as a knight.",
        "reality.tell": "The wounds on his neck are not from this era.",
        "book.desc": "An open book rests on the dead man's chest.",
        "book.tell": "The pages are written in blood.",
    },
    "bk.ch16.barca_encantada": {
        "name": "The Enchanted Boat",
        "reality.desc": "A small boat is tied to the riverbank.",
        "reality.tell": "The boat has no oars but the water moves it.",
        "book.desc": "An enchanted boat floats alone on the river without a crew.",
        "book.tell": "The river waters burn with blue fire under moonlight.",
    },
    "bk.ch17.hombre_muerto": {
        "name": "The Dead Man on the Road",
        "reality.desc": "A corpse lies on the ground, dressed as a knight.",
        "reality.tell": "The man has no visible wounds but is clearly dead.",
        "book.desc": "A book lies on the dead man's chest, its pages glowing.",
        "book.tell": "The book reads the thoughts of anyone who looks at it.",
    },
    "bk.ch18.libros_quemados": {
        "name": "The Burned Books",
        "reality.desc": "A pile of books burns in a bonfire by the roadside.",
        "reality.tell": "The flames are an unnatural green color.",
        "book.desc": "An intact book floats above the flames, unburned.",
        "book.tell": "The fire cannot destroy the knowledge in its pages.",
    },
    "bk.ch20.dulcinea_encantada": {
        "name": "Enchanted Dulcinea",
        "reality.desc": "A peasant girl sits by the roadside, looking at the horizon.",
        "reality.tell": "Her eyes glow with an unnatural light.",
        "book.desc": "A noble lady dressed in silk and jewels looks from a balcony.",
        "book.tell": "Her beauty is eternal, but no one remembers her after seeing her.",
    },
    "bk.ch22.duelo_luz_luna": {
        "name": "The Moonlight Duel",
        "reality.desc": "Two men fight by moonlight in a clearing.",
        "reality.tell": "The shadows of the combatants move independently of them.",
        "book.desc": "Two knights fight under silver moonlight, their swords gleaming.",
        "book.tell": "The moon illuminates only the duelists, leaving everything else in shadow.",
    },
    "bk.ch23.montesinos": {
        "name": "The Cave of Montesinos",
        "reality.desc": "The entrance to a cave opens on the mountainside.",
        "reality.tell": "The air coming from the cave smells of incense and sweat.",
        "book.desc": "An enchanted cave glows with magical light from within.",
        "book.tell": "Whoever enters the cave returns changed, speaking of impossible things.",
    },
    "bk.ch24.altisidora": {
        "name": "Altisidora",
        "reality.desc": "A young maiden sings by a fountain, surrounded by birds.",
        "reality.tell": "Her singing causes flowers to wither when she sings.",
        "book.desc": "A noble maiden sings a song of forbidden love.",
        "book.tell": "Whoever hears her song falls in love forever and never forgets.",
    },
    "bk.ch25.conde_altisidora": {
        "name": "Count Altisidora",
        "reality.desc": "A noble count receives guests in his castle.",
        "reality.tell": "The shadows in his castle move when he isn't looking.",
        "book.desc": "A count in fine clothes hosts an eternal banquet.",
        "book.tell": "The guests at the banquet never age or die.",
    },
    "bk.ch26.melisendra": {
        "name": "Melisendra",
        "reality.desc": "A woman sings next to a puppet theater in the village square.",
        "reality.tell": "The puppets move by themselves when she doesn't touch them.",
        "book.desc": "A sorceress directs a shadow theater where characters come to life.",
        "book.tell": "The shadows predict the future of whoever watches them.",
    },
    "bk.ch27.molinos_llenadores": {
        "name": "The Filling Mills",
        "reality.desc": "Several windmills turn slowly in the plain.",
        "reality.tell": "The mills turn even when there is no wind.",
        "book.desc": "Windmills filling with wine and oil run endlessly under moonlight.",
        "book.tell": "The mills grind not grain, but the dreams of those who watch.",
    },
    "bk.ch28.encantada": {
        "name": "The Enchanted Lady",
        "reality.desc": "A lady sits in a castle balcony, waiting.",
        "reality.tell": "Her face does not reflect the moonlight.",
        "book.desc": "An enchanted lady waits in a tower, surrounded by enchantments.",
        "book.tell": "Only he who breaks the enchantment can see her true face.",
    },
    "bk.ch29.penitentes": {
        "name": "The Penitents",
        "reality.desc": "A group of white-clad penitents walks along the road at dawn.",
        "reality.tell": "Their faces are covered, and they leave no footprints in the dust.",
        "book.desc": "A group of penitents carries white hoods and crosses of fire.",
        "book.tell": "Whoever joins the penitents can never leave the road.",
    },
    "bk.ch30.leones_carro": {
        "name": "The Lions on the Cart",
        "reality.desc": "A cart drawn by lions crosses the road, guided by a keeper.",
        "reality.tell": "The lions have no collars or chains, but they do not attack.",
        "book.desc": "Lions tamed by a magician travel in an enchanted cart.",
        "book.tell": "The lions guard a secret no one must know.",
    },
    "bk.ch31.cueva_hermoso": {
        "name": "Hermoso's Cave",
        "reality.desc": "A dark cave hides behind a waterfall in the mountain.",
        "reality.tell": "The waterfall water flows upward instead of down.",
        "book.desc": "An enchanted cave houses a hermit who knows the future.",
        "book.tell": "The hermit knows the destiny of whoever enters but cannot change it.",
    },
    "bk.ch32.ventura_duque": {
        "name": "The Duke's Venture",
        "reality.desc": "A round stone floor with a mill in the middle and a gap in the wall.",
        "reality.tell": "The mill does not walk but its sails deny the ground within four metres.",
        "book.desc": "A gaunt nine-metre man with a millstone head fights in the castle.",
        "book.tell": "Whoever enters the Duke's castle cannot leave without paying a price.",
    },
    "bk.ch33.leones_reales": {
        "name": "The Royal Lions",
        "reality.desc": "Two lions are caged in the Duke's castle courtyard.",
        "reality.tell": "The lions never blink.",
        "book.desc": "Magical lions guard the Duke's treasure in their enchanted cage.",
        "book.tell": "Whoever steals from the lions will be devoured by his own shadow.",
    },
    "bk.ch34.encantamiento": {
        "name": "The Enchantment",
        "reality.desc": "A castle is surrounded by fog that never lifts.",
        "reality.tell": "The castle walls move when nobody looks.",
        "book.desc": "An enchanted castle is protected by spells impossible to break.",
        "book.tell": "Only he who breaks the enchantment can enter the enchanted castle.",
    },
    "bk.ch35.caballero_blanco": {
        "name": "The Knight of the White Moon",
        "reality.desc": "A rival knight defeats Quixote in combat and sends him home.",
        "reality.tell": "The knight's armor has no dents or scratches.",
        "book.desc": "A rival knight fights with a sword of light.",
        "book.tell": "Whoever defeats the Knight of the White Moon receives an eternal curse.",
    },
    "bk.ch36.cuidado_sancho": {
        "name": "Sancho's Care",
        "reality.desc": "Sancho tends to Quixote's wounds after defeat.",
        "reality.tell": "Sancho cannot sleep while Quixote is wounded.",
        "book.desc": "Sancho tends to Quixote while he sleeps under an enchanted tree.",
        "book.tell": "Quixote's sleep is protected by ancient spells.",
    },
    "bk.ch37.encantamiento_duquesa": {
        "name": "The Duchess's Enchantment",
        "reality.desc": "The Duchess pretends to be enchanted to trick Sancho.",
        "reality.tell": "The Duchess is not really enchanted but pretends well.",
        "book.desc": "The Duchess is truly enchanted and needs help breaking it.",
        "book.tell": "Only he who breaks the Duchess's enchantment can obtain her reward.",
    },
    "bk.ch38.clavileño": {
        "name": "Clavileño",
        "reality.desc": "A wooden horse stands ready for flight in the castle courtyard.",
        "reality.tell": "The wooden horse has no wings but can fly.",
        "book.desc": "Clavileño, the enchanted wooden horse, flies through night skies.",
        "book.tell": "Whoever rides Clavileño sees things no mortal has seen.",
    },
    "bk.ch39.sancho_gobernador": {
        "name": "Sancho Governor",
        "reality.desc": "Sancho governs the ínsula of Barataria with wisdom.",
        "reality.tell": "The island's citizens respect Sancho more than any governor.",
        "book.desc": "Sancho governs an enchanted island where physics do not apply.",
        "book.tell": "Whoever governs the enchanted island will go mad within a month.",
    },
    "bk.ch40.entierro_rico": {
        "name": "The Rich Man's Burial",
        "reality.desc": "A rich man's funeral procession passes by the road.",
        "reality.tell": "The coffin is too light for an adult body.",
        "book.desc": "An enchanted funeral carries an empty coffin.",
        "book.tell": "Whoever opens the coffin finds his own death written inside.",
    },
    "bk.ch41.oviedo": {
        "name": "Oviedo",
        "reality.desc": "A bachelor from Oviedo discusses literature with Quixote.",
        "reality.tell": "The bachelor cannot read or write but discusses literature.",
        "book.desc": "A false book of adventures tells deeds that never happened.",
        "book.tell": "Whoever reads the false book becomes a character in its pages.",
    },
    "bk.ch42.maestro_pedro": {
        "name": "Maestro Pedro",
        "reality.desc": "Maestro Pedro performs his puppet show in the town square.",
        "reality.tell": "The puppets move by themselves when Maestro Pedro does not touch them.",
        "book.desc": "Maestro Pedro's puppet show shows events that have not yet happened.",
        "book.tell": "Whoever watches the puppet show sees his own future in the scenes.",
    },
    "bk.ch43.caso_penal": {
        "name": "The Criminal Case",
        "reality.desc": "A criminal case is brought before the Duke.",
        "reality.tell": "The accused is innocent but everyone thinks him guilty.",
        "book.desc": "An enchanted criminal is judged for crimes he did not commit.",
        "book.tell": "Whoever condemns the enchanted criminal will be condemned in turn.",
    },
    "bk.ch44.duelo_evitados": {
        "name": "The Duels Avoided",
        "reality.desc": "Two knights fight a duel that no one wants to see.",
        "reality.tell": "Both knights fear fighting but will not back down.",
        "book.desc": "Two enchanted knights duel endlessly without hurting each other.",
        "book.tell": "Whoever ends the duel will be forced to fight eternally.",
    },
    "bk.ch45.encantamiento_sancho": {
        "name": "Sancho Enchanted",
        "reality.desc": "Sancho is enchanted and believes he is someone else.",
        "reality.tell": "Sancho does not remember who he really is but acts like another.",
        "book.desc": "Sancho is enchanted by a witch and believes he is a noble.",
        "book.tell": "Whoever disenchants Sancho discovers his true identity.",
    },
    "bk.ch46.leones_corte": {
        "name": "The Court Lions",
        "reality.desc": "Royal lions are caged in the Duke's castle courtyard.",
        "reality.tell": "The lions do not roar but their gaze freezes anyone.",
        "book.desc": "Magical lions guard the Duke's treasure in their enchanted cage.",
        "book.tell": "Whoever steals from the lions will be devoured by his own shadow.",
    },
    "bk.ch47.despedida": {
        "name": "The Farewell",
        "reality.desc": "Quixote and Sancho bid farewell to the Duke and Duchess.",
        "reality.tell": "The Duke and Duchess weep as Quixote and Sancho leave.",
        "book.desc": "An enchanted farewell at the Duke's castle, filled with magical tears.",
        "book.tell": "Whoever witnesses the farewell remembers it forever.",
    },
    "bk.ch48.regreso_pueblo": {
        "name": "Return to the Village",
        "reality.desc": "Quixote and Sancho return home after many adventures.",
        "reality.tell": "The village does not recognize them but they remember every detail.",
        "book.desc": "Quixote and Sancho return to an enchanted village that does not remember its name.",
        "book.tell": "Whoever returns to the enchanted village can never leave it.",
    },
    "bk.ch50.impertinente": {
        "name": "The Curious Impertinente",
        "reality.desc": "A man tells the story of the Curious Impertinente in the inn.",
        "reality.tell": "The story of the Curious Impertinente is too real to be invented.",
        "book.desc": "The story of the Curious Impertinente is told in an enchanted book.",
        "book.tell": "Whoever reads the story of the Impertinente becomes the Impertinente.",
    },
}

# Key suffix -> translation field
KEY_FIELDS = [
    ("name", "name"),
    ("reality.desc", "reality.desc"),
    ("reality.tell", "reality.tell"),
    ("book.desc", "book.desc"),
    ("book.tell", "book.tell"),
]


def process_po(po_path, translations):
    """Fill msgstr for fragment keys and remove dead .01 duplicate keys."""
    with open(po_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Remove dead .01 duplicate key blocks (msgid ...01... + msgstr)
    # Pattern: optional comment line + msgid "....01...." + msgstr "..."
    content = re.sub(
        r'^#\. META: namespace=ui\nmsgid "([^"]*\.01\.[^"]*)"\nmsgstr "[^"]*"\n\n',
        "",
        content,
        flags=re.MULTILINE,
    )

    # 2. Fill msgstr for each fragment key
    filled = 0
    for frag_id in FRAGMENT_IDS:
        trans = translations.get(frag_id, {})
        for suffix, field in KEY_FIELDS:
            if suffix == "name":
                key = f"ui.book.{frag_id}.name"
            else:
                key = f"ui.face.{frag_id}.{suffix}"
            value = trans.get(field, "")
            if not value:
                continue
            # Replace msgstr "" for this specific msgid
            pattern = re.compile(
                r'(msgid "' + re.escape(key) + r'"\n)msgstr ""'
            )
            new_content, n = pattern.subn(
                r'\1msgstr "' + value + '"', content, count=1
            )
            if n > 0:
                content = new_content
                filled += 1

    with open(po_path, "w", encoding="utf-8") as f:
        f.write(content)

    return filled


def main():
    for po_file in PO_FILES:
        po_path = LOCALE_DIR / po_file
        if not po_path.exists():
            print(f"SKIP {po_file}: not found")
            continue
        translations = SP if po_file == "es.po" else EN
        filled = process_po(po_path, translations)
        print(f"{po_file}: filled {filled} translations")


if __name__ == "__main__":
    main()
