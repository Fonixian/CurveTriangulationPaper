#import "@preview/hydra:0.6.3": hydra

#let thesis(doc,
  lang: "hu",
  title : "Sok verejtékkel készült szakdolgozatom címe",
  authors: ( (name: "Hallgató Hanga", course: "Programtervező informatikus BSc"),),
  supervisors :( (name:"Dr. Témavezető Tamás", role : "Egyetemi adjunktus"), ),
  department : "Témavezetőm Tanszéke",
  date : 2026,
  city : "Budapest"
) = {
  // Language
  set text(lang:lang)

  let txt-supervisor-singular = "Supervisor"
  let txt-author-singular = "Author"
  let txt-chapter = "Chapter"
  let txt-section = "Section"
  let txt-plural = "s"
  
  if lang == "hu"{
    txt-supervisor-singular = "Témavezető"
    txt-author-singular = "Szerző"
    txt-chapter = "Fejezet"
    txt-section = "Szakasz"
    txt-plural = "k"
  }

  // General text setup
  set par(leading: 14.5pt, spacing: 14.5pt, first-line-indent: 1.8em, justify: true)
  set text(font: "New Computer Modern",size: 12pt)
  show math.equation: set text(weight: "regular")
  show raw: set text(font: "New Computer Modern Mono", size:10pt)
  show raw.where(block: true): set par(leading: 0.75em)
  set list(indent: 1.5em)
  set enum(indent: 1.5em)
  
  // Heading setup
  set heading(numbering: "1.")
  show heading: set block(above: 1.4em, below: 1em)
  show heading.where(level : 1): set text(30pt)
  show heading.where(level : 1): set block(above: 100em, below: 3em)
  show heading.where(level : 1, numbering : "1."): it => block(above: 100em, below: 3em)[
    #set text(30pt)
    #v(3em)
    #if lang=="hu" [
      #counter(heading).display() Fejezet
    ]else[
      Chapter #counter(heading).display()
    ]#v(1em)
    #par(first-line-indent : 0em, it.body)
  ]
  show heading.where(level : 1) : set heading(supplement: txt-chapter)
  show heading.where(level : 2) : set heading(supplement: txt-section)
  show heading.where(level : 3) : set heading(supplement: txt-section)
  show heading.where(level : 4) : set heading(supplement: txt-section)
  show heading.where(level : 5) : set heading(supplement: txt-section)
  
  // Title page
  page(
    paper:"a4",
    margin : 4.0cm,
    {
      align(top+center)[
        #place(top+left, image("images/elte_cimer_szines.png",width: 27%))
        #place(top+right, text(size:13pt)[
            Eötvös Loránd Tudományegyetem \
            Informatikai Kar \
            Informatikatudományi Intézet \
            #department
          ])
      ]
      align(center+horizon)[
        #text(28pt)[#title]
      ]
      align(bottom+center)[
        #grid(columns: (50%,50%), gutter : 3em,
        align(top+left)[
          _ #txt-supervisor-singular#if supervisors.len()>1 [#txt-plural]: _\
          #for author in supervisors {
            text(size: 12pt,author.name+"\n") 
            text(size: 11pt,author.role)
          }
        ],
        align(top+right)[
          _ #txt-author-singular#if authors.len()>1 [#txt-plural]: _\
          #for author in authors {
            text(size: 12pt,author.name+"\n") 
            text(size: 11pt,author.course)
          }
        ])\
        #city, #date
      ]
    }
  )
    // General page setup
  set page(
      paper: "a4",
      columns: 1,
      margin : 2.5cm, //(top :2.5cm, bottom : 2.5cm, inside: 2.5cm, outside:2.5cm),
      binding: left,
      number-align: center,
      numbering : "1",
      header: context {
        if calc.odd(here().page()) {
          align(right, emph(hydra(1)))
        } else {
          align(left, emph(hydra(2)))
        }
        //line(length: 100%)
      }
    )

  //set heading(numbering: "1.1")
  show heading.where(level: 1): it => pagebreak(weak: true) + it
  // line numbering on code
  show raw.where(block: true): code => {
    grid(
      columns: (auto, auto),
      column-gutter: 1em,
      row-gutter: par.leading,
      align: (right, raw.align),
      ..for line in code.lines {
        (
          text(fill: gray)[#line.number],
          line.body,
        )
      },
    )
  }
  
  doc
}

#show: thesis.with(
  title: "Work-in-progress Typst szakdolgozat sablon",
  authors : ((
    name: "Gipsz Jakab",
    course: "Programtervező informatikus BSc"
  ),),
  supervisors : ((
    name:"Dr. Témavezető Tamás",
    role : "Egyetemi adjunktus"
  ),)
)

#outline()

= Bevezetés <intro>

// Munkám során ahhoz, hogy a Bézier görbéket megjelenítsem a vonalprimitívet cserélem le, ez alatt azt értem, hogy nem a grafikus API-k által kínált vonalprimitíveket használom. Például: GL_LINE_STRIP, D3DPT_LINESTRIP, VK_PRIMITIVE_TOPOLOGY_LINE_STRIP
// Az utóbbira azért van szükség, mert a vonalprimitíveken erős megkötések vannak, például a grafikus API-k nem garantálják, hogy a vonal szélessége megváltoztatható legyen, a DX11-ben nem is lehet megadni a szélességét és még nem is beszéltünk arról az esetről, amikor mintázatot szeretnénk futtatni a görbe mentén. Valamint mintázatokat sem támogatnak alapból a grafikus API-k.

// Ez egy olyan probléma, amire több megoldás is létezik, de általában mindegyiknak megvan a saját hátránya vagy nem támogatja az összes funkciót, ami számomra szükséges.

== Bézier-görbék
// https://onlinelibrary.wiley.com/doi/10.1155/2013/171392
// https://books.google.hu/books?id=YmQy799flPkC&pg=PA264&redir_esc=y#v=onepage&q&f=false
// https://books.google.hu/books?id=TAYw3LEs5rgC&pg=PA404&redir_esc=y#v=onepage&q&f=false

Egy $n$-ed fokú Bézier-görbét $n+1$ kontrollponttal adok meg: $bold(P)_0, dots, bold(P)_n$. A görbe pontjait a $t in [0, 1]$ paraméterrel számolom:

$ bold(B)(t) = sum_(i=0)^n b_(i,n)(t) bold(P)_i, quad b_(i,n)(t) = binom(n, i) t^i (1-t)^(n-i). $

A $b_(i,n)$ függvények a Bernstein-polinomok. Minden $t$ értéknél nemnegatívak, és az összegük egy, ezért a görbe minden pontja a kontrollpontok súlyozott átlaga. Ebből következik a konvex burok tulajdonság is.

Négy kontrollponttal adom meg a harmadfokú görbét:

$ bold(B)(t) = (1-t)^3 bold(P)_0 + 3(1-t)^2 t bold(P)_1 + 3(1-t) t^2 bold(P)_2 + t^3 bold(P)_3. $

Ugyanez mátrixalakban, amit programkódban is tömören ki tudok értékelni:

$ bold(B)(t) = mat(1, t, t^2, t^3) mat(1, 0, 0, 0; -3, 3, 0, 0; 3, -6, 3, 0; -1, 3, -3, 1) vec(bold(P)_0, bold(P)_1, bold(P)_2, bold(P)_3). $

A de Casteljau-algoritmussal lineáris interpolációk sorozatával számolom ki ugyanezt a pontot. Kezdetben $bold(P)_i^((0)) = bold(P)_i$, majd

$ bold(P)_i^((k)) = (1-t) bold(P)_i^((k-1)) + t bold(P)_(i+1)^((k-1)), $

és a görbe pontja $bold(B)(t) = bold(P)_0^((n))$. A közbenső pontokkal a görbét a $t$ helyen két Bézier-görbére oszthatom, és ezek kontrollpontjai éppen a $bold(P)_0^((k))$, illetve a $bold(P)_k^((n-k))$ pontok.

A harmadfokú görbe deriváltja:

$ bold(B)'(t) = 3 [(1-t)^2 (bold(P)_1 - bold(P)_0) + 2(1-t)t (bold(P)_2 - bold(P)_1) + t^2 (bold(P)_3 - bold(P)_2)]. $

A végpontokban ez $bold(B)'(0) = 3(bold(P)_1 - bold(P)_0)$ és $bold(B)'(1) = 3(bold(P)_3 - bold(P)_2)$, vagyis a görbe érintője a végpontokban a szomszédos kontrollponton halad át.

Munkám során Bézier-görbék megjelenítésével foglalkozom, azon belül is a harmadfokú Bézier-görbékkel. Ezt a döntést három érvvel indokolom:
- A Bézier-görbék a legelterjedtebbek a CAD- és a grafikai tervezőszoftverekben.
- Az SVG specifikációja a másod- és a harmadfokú Bézier-görbéket tartalmazza.
- Több más görbét is át tudok írni Bézier-görbévé: tetszőleges n-ed fokú polinomot fel tudok írni n-ed fokú Bézier-görbeként, a harmadfokú Catmull-Rom spline, Hermite spline és B-spline szakaszai pedig pontosan megegyeznek egy-egy harmadfokú Bézier-görbével.

A Bézier-görbéknek további hasznos tulajdonságaik is vannak:
- Konvex burok tulajdonság: a görbe minden pontja a kontrollpontok konvex burkán belül van.
- Affin invariancia: affin transzformáció után a görbe megegyezik azzal a görbével, amelyet a transzformált kontrollpontokból építek fel.
- Végpont-interpoláció: a görbe kezdőpontja az első, végpontja az utolsó kontrollponttal egyezik meg.
- Fokszámemelés: egy n-ed fokú Bézier-görbét pontosan fel tudok írni n+1-ed fokú Bézier-görbeként.

A fokszámemelés miatt elég a harmadfokú Bézier-görbék megjelenítését megvalósítanom: a lineáris és a másodfokú görbét harmadfokú alakra írom át, és ugyanúgy rajzolom ki.

```cpp
std::array<Vec3, 4> LinearToCubic(Vec3 p0, Vec3 p1) {
    return {
        p0,
        (2.0 * p0 + p1) / 3.0,
        (p0 + 2.0 * p1) / 3.0,
        p1,
    };
}

std::array<Vec3, 4> QuadraticToCubic(Vec3 p0, Vec3 p1, Vec3 p2) {
    return {
        p0,
        (p0 + 2.0 * p1) / 3.0,
        (2.0 * p1 + p2) / 3.0,
        p2,
    };
}
```

== Jelenlegi módszerek

Háromdimenziós görbék megjelenítésére több módszert megvizsgáltam, és három kategóriába soroltam őket: vonalprimitívre, vektorgrafikára és generált geometriára épülő módszerek. Mindegyiknél a következő szempontokat vizsgálom:
- Távolságtól független vastagság, azaz a görbe vastagságát pixelekben adhatom meg.
- Változtatható vastagság, azaz a vastagság értékét módosíthatom.
- Mintázatok támogatása, azaz a görbe nem csak egy színből áll, hanem szaggatott vagy pontozott görbét is megjeleníthetek.
- Térbeli használat, azaz a görbét nem csak egy síkban adhatom meg.
- Portabilitás
Más szempontok is vannak, például a színek és az átlátszóság kezelése, az anti-aliasing és a teljesítmény, de ezekre csak néhány helyen térek ki ebben a fejezetben.

=== Vonalprimitíven alapuló módszerek

Vonalprimitívvel egyenes szakaszokat rajzolhatok: ilyen például a `GL_LINE_STRIP`, a `D3DPT_LINESTRIP` és a `VK_PRIMITIVE_TOPOLOGY_LINE_STRIP`. A Bézier-görbét ezért pontokban értékelem ki, és a pontokat vonalprimitívvel kötöm össze. A kapott törtvonal annál pontosabban közelíti a görbét, minél több pontban értékelem ki.

- `glLineStipple`: tizenhat bites bitmaszkkal és egy faktorral adom meg a raszterizált mintázatot. Nagy hátránya, hogy a legacy OpenGL fixed function pipeline része, amelyet a mai alkalmazások már nem használnak. Az /*@vs_segment_curve*/ ábrán látható, hogyan néz ki az eredmény.
- `VK_KHR_line_rasterization`: gyakorlatilag a `glLineStipple` utódja egy modern API-ban. A bővítményt elsősorban CAD-alkalmazásokban használják. Ugyanúgy bitmaszkkal és faktorral adom meg a mintázatot, emellett a vonalraszterizációs algoritmust is kiválaszthatom. Nagy hátránya, hogy nem minden eszköz implementálja, vagy nem teljesen, lásd /*@amd_impl_table*/. Emellett ez egy Vulkan-specifikus bővítmény.

//#figure(
//  image("images/vk_segment_curve_combined.png",width:100%),
//  caption: [VK_KHR_line_rasterization (SmoothLine) használatával megjelenített szegmens és görbe.]
//) <vs_segment_curve>

//#figure(
//  table(
//    columns: 2,
//    [Algoritmus], [Implementált],
//    [bresenhamLines], [Igen],
//    [rectangularLines], [Nem],
//    [smoothLines], [Nem],
//    [stippledBresenhamLines], [Igen],
//    [stippledRectangularLines], [Nem],
//    [stippledSmoothLines], [Nem]
//  ),
//  caption: [AMD Radeon(TM) 610M (2022) által támogatott algoritmusok],
//) <amd_impl_table>

- Vertex és fragment shader: a legegyszerűbb megoldás, hogy a vertex shaderben kiszámolom a pont képernyőkoordinátáit, a fragment shaderben pedig az interpolált értékből meghatározom, mely fragmenteket dobom el. Az /*@gl_segment_curve*/ ábrán látszik, hogy a mintázat nem megfelelő, mert a szegmensek hossza nem egyezik meg a mintázat hosszával. Ezt kiküszöbölhetem úgy, hogy a CPU-n kiszámolom a görbe ívhosszát az adott pontig. Ezt viszont minden képkockánál újra kell számolnom, mert a mintázat képernyőtérben van, a kamera pedig mozoghat. Ha kiszámolom, a /*@vs_segment_curve*/ ábrához hasonló görbét kapok.

//#figure(
//  image("images/gl_segment_curve_combined.png",width:100%),
//  caption: [Vertex és fragment shader használatával megjelenített szegmens és görbe.]
//) <gl_segment_curve>

Az /*@vs_segment_curve*/ ábrán olyan hiba is látszik, hogy a szaggatások a görbületnél rossz irányba állnak, és keresztezik egymást. Ez azért történik, mert a görbe egyenes szakaszokból áll, és a szaggatásos mintázat merőleges ezekre a szakaszokra.

Összefoglalva, a vonalprimitíveknek három nagy hátránya van a görbék rajzolásában:
- A vonalvastagság nem biztosított: OpenGL core profilban az 1-nél nagyobb vastagság nem biztos, hogy működik, Vulkanban a vastag vonalhoz a választható `wideLines` funkcióra van szükség, a DX11-ben pedig egyáltalán nem adhatok meg vonalvastagságot.
- A vertex és a fragment shader szempontjából a vonalnak nincs vastagsága. A vonal hossza mentén interpolált értékeket adhatok meg, a szélesség mentén nem. Ezért csak különböző szaggatásokat hozhatok létre, a görbe végét viszont nem tudom lekerekíteni.
- Ha vastag vonalakból állítom össze a solid görbét, az nem szép /*@line_solid_curve*/, mert a szegmenseket a két végpontjukon túl nem tudom meghosszabbítani, ezért az illesztéseknél rések maradnak. Ha szegmens végpontokat eltolom, akkor a sarkok nyúlnak túl a görbén.

//#figure(
//  image("images/vk_curve_thick_solid.png",width:80%),
//  caption: [Vastag görbe vonalprimitívekkel kirajzolva]
//) <line_solid_curve>

// One large after every one
//A módszereket a @line_table táblázat foglalja össze a fejezet elején felsorolt szempontok //szerint.
//
//#figure(
//  table(
//    columns: 6,
//    align: (left, center, center, center, center, center),
//    [Módszer], [Pixelben megadott vastagság], [Változtatható vastagság], [Mintázat], //[Működik térben], [Portabilitás],
//    [glLineStipple], [Igen], [Eszközfüggő], [Igen], [Igen], [Nem],
//    [Vulkan], [Igen], [Eszközfüggő], [Igen], [Igen], [Nem],
//    [Vertex + Fragment], [Igen], [Eszközfüggő], [Részben], [Igen], [Igen],
//  ),
//  caption: [A vonalprimitíven alapuló módszerek összehasonlítása.]
//) <line_table>

=== Vektorgrafika

Több interfész létezik GPU-val gyorsított vektorgrafikára, így Bézier-görbék megjelenítésére is, például az OpenVG és az NV_path_rendering. Ezekkel SVG-útvonalakat jeleníthetek meg, ezért az SVG-útvonalak teljes eszköztárát használhatom. Az SVG-ben a `stroke-dasharray` attribútummal szaggatott vagy pontozott vonalat adhatok meg: a `16 10` értékkel például 16 egység hosszú szakaszokat és 10 egység hosszú réseket kapok, a `0 10` értékkel pedig kerek vonalvégek (`stroke-linecap="round"`) mellett pontokat. Egyetlen útvonalba több Bézier-görbét is felfűzhetek (`C` és `S` parancsok), és a mintázat ilyenkor az útvonal ívhossza mentén az illesztéseknél is folyamatos marad.

Hátrányuk, hogy csak kétdimenziós megjelenítésre alkalmasak. Megkerülhetném ezt úgy, hogy a CPU-n kiszámolom a kontrollpontok képernyőkoordinátáit, de ez Bézier-görbéknél nem elég. A Bézier-görbék ugyan affin invariánsak, a 3D-s alkalmazások perspektív vetítése viszont nem affin. Vetítés után racionális Bézier-görbét kapok, amelyet ezekkel az interfészekkel nem tudok megjeleníteni. Ezért két lehetőségem marad: pontok sorozataként adom meg a görbét, vagy de Casteljau-algoritmussal addig osztom kisebb Bézier-görbékre, amíg a hiba elég kicsi nem lesz. Mindkét módszernél sok CPU-időt használok fel, mert minden képkockánál újra kell számolnom.

Emellett ezekkel az interfészekkel az ábra elemeit festőalgoritmussal rajzolom ki, ezért nem tudok mélységet használni, és nem tudom kezelni azt az esetet, amikor két görbe takarja egymást. Az NV_path_rendering támogatja a mélységet, de az az ábra síkjának mélységére vonatkozik, nem a benne lévő elemekére.

Ezeknél az interfészeknél egy másik probléma, hogy változó geometria megjelenítésére nem alkalmasak. Affin transzformációkat, például forgatást és eltolást minimális költséggel hajthatok végre rajtuk. A kontrollpontok módosítása viszont jelentős költséget jelent.

#figure(
  image("images/spiral.png",width:30%),
  caption: [Spirál több Bézer szegmenssel kirajzólva, ahol először a kék elemek lettek kirajzolva, majd a narancssárga elemek]
) <spiral>

//#figure(
//  image("images/nvpr_2d.png",width:80%),
//  caption: [NV_path_rendering használatával elkészített 2D Bézier görbék]
//) <nvpr_2d>

//#figure(
//  image("images/nvpr_3d.png",width:80%),
//  caption: [NV_path_rendering használatával elkészített 3D Bézier görbék]
//) <nvpr_3d>
// TODO jobb ábra a hibás mélységekre.

=== Generált geometria

Mivel a grafikus API-k vonalprimitívei nem elegendők vastag görbék megjelenítésére, a görbét magamnak kell előállítanom, és erre több módszer is létezik. Ezeket két kategóriába sorolom: az egyik módszer a geometriával közelíti a lehető legjobban a görbe alakját, a másik csak közelíti a görbét, és a görbe alakját a pixel shaderben, fragmentek eldobásával alakítom ki.

Az egyik legegyszerűbb módszer a geometria shader használata: a bejövő görbe két szomszédos pontjából egy négyszöget állítok elő, majd a pixel shaderben lekerekítem a sarkokat. Ennél a módszernél geometria shader helyett csak vertex shadert is használhatok, például az API-k instanced rajzolási parancsaival, ahol "ugyanazt" a négyszöget rajzolom ki különböző eltolásokkal.

Ennek a módszernek egy másik változata, hogy a sarkokat nem a pixel shaderben kerekítem le, hanem négyszög helyett bonyolultabb alakot, mondjuk egy kétdimenziós kapszulát használok, amelynek mindkét vége félkör alakú.

A két módszerrel az a problémám, hogy az átlátszóságot nem tudom jól kezelni, mert a görbe két szomszédos szegmense fedi egymást. Ezért a görbén olyan pontok jelennek meg, ahol az alpha blending során kétszer adom hozzá a görbe színét. Emellett a görbéknél gyakran alpha blendinggel valósítom meg az anti-aliasingot, ezért akkor is megjelenhetnek hibák, ha a görbe nem átlátszó.

Ezeknek a módszereknek a hibáit úgy csökkentem, hogy a szegmensekre osztott görbét háromszögelem. Így elkerülöm, hogy két egymást követő szegmens fedje egymást. Ilyen háromszögelést használ az ImGui a CPU-n, Rye Terrell pedig a GPU-n. Az utóbbi megoldással olyan problémáim vannak, hogy a szegmenseket összekötő join egy külön drawcall, valamint az implementációjában nem kezel le minden esetet és így könnyen lehet olyan ábrát kétrehozni, ahol a háromszögelésnél nagy hiba keletkezik.


//Mivel a vonalprimitívekkel nem lehet szép vastag görbét létrehozni, ezért nekünk kell elkészítenünk a geometriát.
//Rye Terrell által készített 


// Jelenlegi módszerek előnyök hátrányok képek (forrás)
//- opengl 2.0 api
//- https://wwwtyro.net/2019/11/18/instanced-lines.html (Összehasonlítás) (solid)
//- VK_KHR_line_rasterization
//- https://github.com/ocornut/imgui/wiki/Pixel-Perfect-Rendering
//- https://developer.nvidia.com/nv-path-rendering
//- https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects///chapter-25-rendering-vector-art-gpu
//- http://artgrammer.blogspot.com/2011/07/drawing-polylines-by-tessellation.html
//- Előző munkám

== Görbeváltozatok

Kirajzolás szempontjából három görbetípust különböztetek meg: Solid, Dotted és Patterned. Mindháromnál megadom a görbe végeinél a kupakokat (Round, Square, Butt, Triangle In, Triangle Out), az interpolálandó színeket, a szélességet, valamint azt, hogy csatlakozzanak-e az előző görbéhez.
- Solid: a görbének csak kupakjai vannak.
- Dotted: megadom, hogy milyen távol legyenek egymástól a pontok, és egy pont a két megadott kupakból áll.
- Patterned: a görbét szegmensekre osztom, és a szegmenseknek adok kupakokat.

Az alkalmazásban a görbéknek egy közös interfésze van a görbe jellemzőinek megadására. A görbetípusok között a spacing és a dash_length argumentumok alapján döntök. Ha a görbe spacing adattagja nulla, akkor Solid, ha a spacing nem nulla, de a dash_length nulla, akkor Dotted, különben Patterned.

A görbeváltozatokra azért van szükségem, mert minimalizálni szeretném az elvégzendő munkát. Például a Patterned görbénél szükségem van a görbe ívhosszára, a Solid görbénél viszont nincs rá szükségem. A Dotted görbénél pedig nem kell előállítanom a görbét, mivel elég kiszámolnom a mintázatok helyét, és négyszögeket rajzolni.

Végül az alkalmazásban használt görbéket a generált geometria módszerével készítem el. Az elsődleges célom a CPU-használat minimalizálása anélkül, hogy a funkciókat feláldoznám. Másodlagos célom, hogy a görbéket könnyen bővíthessem más tulajdonságokkal, például új minták hozzáadásával vagy változó vonalvastagsággal.

= Geometria generálás

Mivel a görbéket futás közben szeretném módosítani, nincs lehetőségem offline elkészíteni a háromszögelésüket, vagy egyszer kiszámolni, majd újra felhasználni őket. Mivel egy-egy görbénél a felbontást előre megadom, azaz nem függ a görbe alakjától, ezt a feladatot könnyen párhuzamosíthatom.

Ha veszek egy harminckettes felbontású görbét, akkor a Bézier-görbét harminckét helyen értékelem ki, és ezekből az értékekből harmincegy szegmenst kell létrehoznom. Egy szegmens alakjának meghatározásához elég négy pontot ismernem, lásd @4point_segment.

#figure(
  image("images/segment_from4point.png",width:80%),
  caption: [Egy szegmens előállításához csak négy szomszédos pont szükséges]
) <4point_segment>

Egy-egy szegmens csatlakozásnál maximum három pontot használok és azok három szomszédos ponttól függenek, ezért egyszerübb magugat a sarkokat venni. A sarkoknál négy plusz egy esetet különböztetek meg, és ezek befolyásolják a háromszögelést.
- Egyenes eset: amikor három egymást követő pont egy egyenesbe esik.
- Tompa szög: amikor a három egymást követő pont tompaszöget alkot. Ilyenkor a görbe szegmenseknél miter-csatlakozást alkalmazok.
- Hegyes szög: amikor a három egymást követő pont hegyesszöget alkot. Ilyenkor a görbe szegmenseknél bevel-csatlakozást alkalmazok, pontosabban olyan bevelt, amelyet a vonalvastagság felével eltolok.
- Overlap: ez az eset akkor fordul elő, amikor a görbe szakasza túl rövid az adott szög és vonalvastagság mellett. Ilyenkor a belső miter csúcs túlnyúlna a szegmensen, és elrontaná a háromszögelést, ezért a két szegmenst a sarkon túl meghosszabbítom, és hagyom, hogy fedjék egymást.
- Görbe vég: ez az eset akkor áll fenn, amikor a görbe első vagy utolsó pontjánál nincs három egymást követő pontom.

#figure(
  image("images/triangulation_combined.png",width:80%),
  caption: [Háromszögelések esete]
) <triangulation>

Először a háromdimenziós pontokat képernyő-koordinátarendszerbe képezem, mivel a görbék vastagságát pixelekben adom meg, és a háromszögelés is két dimenzióban történik. A $bold(p)$ világkoordinátájú pontból a nézeti-vetítési mátrixszal kapom az $(x, y, z, w)$ vágási koordinátát, majd a perspektív osztás után $(x\/w, y\/w)$ a $W times H$ méretű képernyőre képezem:

$ bold(p)_"px" = (1/2 vec(x\/w, y\/w) + vec(1/2, 1/2)) * vec(W, H). $

Minden szegmenst egy ötcsúcsú háromszögsávként (triangle strip) rajzolok ki, így egy szegmens három háromszögből áll: $(0, 1, 2)$, $(1, 2, 3)$ és $(2, 3, 4)$. A 0-s és 1-es csúcs a szegmens kezdőpontjában, a 2-es, 3-as és 4-es csúcs a végpontjában van. A 4-es csúcs csak a hegyes szögű bevelnél kap saját helyet, minden más esetben egybeesik a 3-as csúccsal, ezért az utolsó háromszög elfajult, és a raszterizáló eldobja.

Minden csúcs a többitől függetlenül, csak a saját sarkát nézve számolja ki a helyét. Jelölje $bold(C)$ a csúcs sarkát, $bold(Q)$ a szegmens másik végpontját, $bold(N)$ pedig a sarkon túli szomszédos pontot. A kezdőpont csúcsainál a szegmenst visszafelé járom be: $bold(C) = bold(P)_i$, $bold(Q) = bold(P)_(i+1)$ és $bold(N) = bold(P)_(i-1)$; a végpont csúcsainál $bold(C) = bold(P)_(i+1)$, $bold(Q) = bold(P)_i$ és $bold(N) = bold(P)_(i+2)$. Így a szegmens mindkét végén ugyanazok a képletek érvényesek. A $w$ vonalvastagságból $h = w/2$ a félvastagság. A sarokba befutó és onnan kifutó irány:

$ bold(d)_"be" = (bold(C) - bold(Q)) / l_"be", quad bold(d)_"ki" = (bold(N) - bold(C)) / l_"ki", quad l_"be" = |bold(C) - bold(Q)|, quad l_"ki" = |bold(N) - bold(C)|. $

Mindkét irányvektort 90 fokkal az óramutató járásával megegyező irányba forgatom, így kapom az $bold(r)_"be"$ és $bold(r)_"ki"$ normálvektort, ahol $bold(r) = (d_y, -d_x)$. Az $alpha$ fordulási szöget a $cos alpha = bold(d)_"be" dot bold(d)_"ki"$ összefüggés adja meg: $cos alpha = 1$ egyenes haladást, $cos alpha = -1$ teljes visszafordulást jelent. A fordulási szög nem a két szegmens által bezárt szög, hanem annak kiegészítője: a bezárt szög $180 degree - alpha$.

A csúcs helye $bold(C) + h bold(o)$, ahol $bold(o)$ a félvastagság egységében mért eltolás. Az $s = plus.minus 1$ előjel megadja, hogy a csúcs a sarok saját koordinátarendszerében a jobb ($s = 1$: 0-s, 3-as és 4-es csúcs) vagy a bal oldalon ($s = -1$: 1-es és 2-es csúcs) van. Mivel a kezdőpontot visszafelé nézem, a 0-s és a 2-es csúcs fizikailag a görbe ugyanazon oldalára kerül, az 1-es és a 3-as pedig a másikra. A pixelben kapott eltolást végül normalizált eszközkoordinátává alakítom, és hozzáadom a sarok vetített helyéhez: $bold(C)_"NDC" + (2h) / vec(W, H) dot.o bold(o)$.

*Tompa szög* ($cos alpha >= 0$, azaz $alpha <= 90 degree$). Mindkét oldalon miter csatlakozást alkalmazok:

$ bold(m) = (bold(r)_"be" + bold(r)_"ki") / (1 + cos alpha), quad bold(o) = s bold(m). $

Mivel $|bold(r)_"be" + bold(r)_"ki"| = 2 cos(alpha/2)$ és $1 + cos alpha = 2 cos^2(alpha/2)$, ezért $|bold(m)| = 1 / cos(alpha/2)$, és $bold(m)$ a két normális szögfelezőjébe mutat. A $bold(C) plus.minus h bold(m)$ pont tehát pontosan a két szegmens $h$ távolságra eltolt szélének metszéspontja, és ehhez sem normalizálásra, sem szögfüggvényre nincs szükségem. A sarokban találkozó két szegmens ugyanazt a két metszéspontot számolja ki, ezért köztük nem marad rés, és nem is fedik egymást. A 4-es csúcs egybeesik a 3-assal.

*Egyenes eset* ($cos alpha = 1$). Ekkor $bold(r)_"be" = bold(r)_"ki"$, ezért a miter képlete $bold(m) = (2 bold(r)_"be") / 2 = bold(r)_"be"$-re egyszerűsödik, és a csúcsok a $bold(C) plus.minus h bold(r)_"be"$ pontokba kerülnek. A szegmens egy $l_"be" times 2h$ méretű téglalap, amelyet a két háromszög átlósan oszt ketté (@triangulation, első sor). Az egyenes esetet tehát nem kezelem külön, a tompa szög képletéből adódik.

*Hegyes szög* ($cos alpha < 0$). Ahogy $alpha$ a 180 fokhoz közelít, $|bold(m)| = 1/cos(alpha/2)$ a végtelenhez tart, ezért a külső oldalon a miter csúcs túl messze kerülne a görbétől. A belső oldalon viszont a miter csúcs a görbén belül marad, ott továbbra is azt használom. A belső oldal az, amerre a görbe fordul: a sarok saját koordinátarendszerében a jobb oldal, ha $bold(r)_"ki" dot bold(d)_"be" < 0$. Legyen $sigma = 1$, ha a belső oldal a jobb, különben $sigma = -1$. A belső oldali csúcs eltolása

$ bold(o) = sigma bold(m). $

A külső oldalon a bevel egyenese merőleges a $bold(b) = bold(m) \/ |bold(m)|$ szögfelezőre, és $h$ távolságra van $bold(C)$-től, vagyis érinti a kerek csatlakozás $h$ sugarú körét. Ezt az egyenest metszem el a befutó szegmens külső szélével, a $bold(C) - sigma h bold(r)_"be" + u bold(d)_"be"$ egyenessel. Mivel $bold(r)_"be" dot bold(b) = cos(alpha/2)$ és $-sigma bold(d)_"be" dot bold(b) = sin(alpha/2)$, a $(bold(x) - bold(C)) dot (-sigma bold(b)) = h$ feltételből

$ u = h (1 - cos(alpha/2)) / sin(alpha/2) = h tan(alpha/4). $

A külső oldali csúcs tehát a befutó szegmens szélén, a sarkon $h tan(alpha/4)$ távolsággal túl van, a 4-es csúcs pedig ugyanígy a kifutó szegmens szélén, a sarok előtt:

$ bold(o) = -sigma bold(r)_"be" + tan(alpha/4) bold(d)_"be", quad bold(o)_4 = -sigma bold(r)_"ki" - tan(alpha/4) bold(d)_"ki". $

A $tan(alpha/4)$ értékét sem szögfüggvénnyel számolom: $cos(alpha/2) = bold(r)_"be" dot bold(b)$, és $tan(alpha/4) = sqrt((1 - cos(alpha/2)) / (1 + cos(alpha/2)))$. A $(2, 3, 4)$ háromszög, amelynek csúcsai a belső miter csúcs és a két külső pont, tölti ki a két szegmens közötti ékét (@triangulation, utolsó sor, kék). A következő szegmens kezdőpontjánál a saját koordinátarendszerében $bold(d)'_"be" = -bold(d)_"ki"$, $bold(r)'_"be" = -bold(r)_"ki"$, és a fordulás iránya is megfordul, azaz $sigma' = -sigma$. A külső csúcsa így $-sigma' bold(r)'_"be" + tan(alpha/4) bold(d)'_"be" = bold(o)_4$, vagyis pontosan a 4-es csúcsra esik. Mivel kezdőpontnál nincs 4-es csúcs, az éket csak a korábbi szegmens rajzolja ki, ezért ott sem marad rés, és nincs átfedés.

*Overlap*. A belső miter csúcs a sarokból mindkét szegmens mentén $h tan(alpha/2)$ távolságra hátrál. Ha ez nagyobb, mint a két szegmens közül a rövidebbik, azaz

$ h tan(alpha/2) > min(l_"be", l_"ki"), $

akkor a belső csúcs a szegmens másik végén is túlnyúlik, a háromszögsáv átfordul önmagán, és a háromszögelés elromlik. A $tan(alpha/2)$ értékét a $bold(d)_"ki"$ és a $bold(b)$ szögfelező közötti $beta = 90 degree - alpha/2$ szögből számolom: $cos beta = |bold(d)_"ki" dot bold(b)|$, és $tan(alpha/2) = cos beta \/ sqrt(1 - cos^2 beta)$. Közel teljes visszafordulásnál ($cos alpha <= -0.9996$) a miter vektor numerikusan is használhatatlan, ezért ezt degenerált esetnek tekintem. Ilyenkor lemondok a csatlakozás geometriájáról, és a szegmenst a sarkon túl $h$ távolsággal meghosszabbított téglalapként rajzolom ki:

$ bold(o) = bold(d)_"be" + s bold(r)_"be". $

A túlnyúló részt a pixel shader alakítja ki a csatlakozás típusa szerint: kerek csatlakozásnál a $bold(C)$ középpontú, $h$ sugarú félkört hagyja meg, szögletesnél a téglalapot változatlanul. A két szegmens ilyenkor fedi egymást (@triangulation, bal alsó rész), ezért átlátszó színnél az átfedésben kétszer keverem be a görbe színét. Ezt elfogadom, mert csak rövid szegmenseknél és éles fordulóknál fordul elő, ahol a hiba kis területre esik. Tompa szögnél nem vizsgálom az átfedést, mert ott $tan(alpha/2) <= 1$, a belső csúcs tehát legfeljebb $h$ távolságra hátrál, és ez csak $h$-nál rövidebb szegmenseknél okoz hibát.

*Görbe vég*. Ha a sarokban nincs szomszédos szegmens, mert a pont a görbe első vagy utolsó pontja, akkor a szomszédos pont helyére a szegmens másik végpontját teszem: $bold(N) = bold(Q)$. Ekkor $bold(d)_"ki" = -bold(d)_"be"$ és $cos alpha = -1$, vagyis a görbe vége a teljes visszafordulás esete, és külön elágazás nélkül az overlap képletét kapja:

$ bold(o) = bold(d)_"be" + s bold(r)_"be". $
/*
A szegmens tehát $h$ távolsággal túlnyúlik a görbe végén, és ebből a téglalapból a pixel shader vágja ki a görbéhez megadott kupakot: Butt kupaknál a végpontnál levágja, Square kupaknál a téglalapot meghagyja, Round kupaknál $h$ sugarú félkört, Triangle Out és Triangle In kupaknál pedig háromszöget formál belőle. Egyik kupak sem nyúlik $h$-nál messzebbre a végponttól, ezért a meghosszabbítás mindegyikhez elég.

A pixel shader a görbe alakját két interpolált koordinátából számolja. Az $a$ hossz menti koordináta a szegmens kezdőpontjában 0, a végpontjában $l_"be"$, a kettő között lineáris. A kezdőpont csúcsainál $a = -h (bold(o) dot bold(d)_"be")$, a végpont csúcsainál $a = l_"be" + h (bold(o) dot bold(d)_"be")$, így a meghosszabbított csúcsoknál $a = -h$, illetve $a = l_"be" + h$. Az oldalirányú koordináta a sáv két szélén $plus.minus h$, a 4-es csúcsnál pedig az eltolás $bold(r)_"be"$-re vett vetülete. Mindkettőt perspektív korrekció nélkül interpolálom, mivel képernyőtérben számoltam őket.
*/
== Segment Clipping <segment_clipping>

A háromszögelés képernyő koordináta rendszerben, a perspektív osztás után történik, ezért a szegmenst még az osztás előtt, látógúla alapján vágnom kell. A raszterizáló ugyan maga is vágja a háromszögeket, de a vertex shader már a $w$-vel osztott pontokkal számol és ha a vágást nem teszem meg, akkor hibás pontokkal számolnám.

#figure(
  image("images/why_need_clipping.png",width:70%),
  caption: [Ha nem vágom el a szakoszokat a látógúla éleinél, akkor rosszak a vetített egyenesek a képernyő koordinátarendszerben.]
) <why_clip>

Egy $(x, y, z, w)$ koordinátájú pont a látógúlán belül van, ha mind a hat síktól mért távolsága nemnegatív. Az oldalsíkoknál ezek a távolságok
$ w + x, quad w - x, quad w + y, quad w - y. $
A mélységnél a szokásos, $[0, 1]$ mélységtartományú vetítésben a közeli sík $z = 0$, a távoli sík pedig $z = w$ (ez a használt vetítési mátrixtól függ, reversed-Z esetén például a két sík felcserélődik), a két mélységi távolság tehát
$ z, quad w - z. $
Jelölje $D_k (bold(p))$ a $bold(p)$ pont $k$-adik síktól mért távolságát, azaz a fenti hat kifejezés közül a $k$-adikat. Mivel ezek a távolságok a vágási térben, azaz a homogén koordinátákban, a $w$-vel való osztás előtt lineárisak, a szegmens $bold(A)$ és $bold(B)$ végpontja között $bold(A) + t (bold(B) - bold(A))$ alakban mozogva a $k$-adik sík távolsága is lineárisan változik $D_k (bold(A))$ és $D_k (bold(B))$ között. A síkot ott metszi a szegmens, ahol
$ t_k = -(D_k (bold(A))) / (D_k (bold(B)) - D_k (bold(A))). $

A vágás a Liang--Barsky-algoritmust követi @liang-barsky:
- Ha minden $k$-ra $D_k (bold(A)) >= 0$ és $D_k (bold(B)) >= 0$, akkor a szegmenst nem kell vágnom.
- Ha van olyan $k$, amelyre $D_k (bold(A)) < 0$ és $D_k (bold(B)) < 0$, akkor a szegmenst eldobom: a csúcs pozíciója NaN lesz, így a raszterizáló az összes háromszögét eldobja. Ugyanígy dobom el a szegmenst akkor is, ha valamelyik végpontja már NaN.
- Különben a $D_k (bold(B)) - D_k (bold(A)) > 0$ síkok $t_k$ értékei közül a legnagyobb adja a $t_0$, a $D_k (bold(B)) - D_k (bold(A)) < 0$ síkoké közül a legkisebb a $t_1$ értéket, $t_0 >= 0$ és $t_1 <= 1$ mellett. Ha $t_0 >= t_1$, akkor nincs olyan $t$, amelyre minden $D_k$ nemnegatív, ezért ezt a szegmenst is eldobom. Egyébként az új végpontok $bold(A) + t_0 (bold(B) - bold(A))$ és $bold(A) + t_1 (bold(B) - bold(A))$.

A homogén koordinátákban végzett lineáris interpoláció a vetítés után is a szegmens egy pontját adja, ezért a vágott végpontokat ugyanúgy oszthatom el $w$-vel, mint az eredetieket. A többi görbe mentén interpolált értékeket, például a színt és az ívhosszokat is $t_0$ és $t_1$ paraméterrel interpolálom a két végpont között.

A vágás a háromszögelést is befolyásolja. Ha $t_0 > 0$, akkor a szegmens kezdőpontját levágtam, és a kezdőpont előtti szomszédos pont már nem a sarok szomszédja; ugyanez igaz a végpontra, ha $t_1 < 1$. Ilyenkor úgy veszem, hogy abban a pontban végetért a görbe.

A szomszédos pontot nem vágom a szegmenssel együtt, mert abból csak az irányt használom. Ha viszont a közeli sík mögé esik, akkor a perspektív osztás után rossz irányt adna @why_clip, ezért a sarokpont felé húzom egészen a közeli síkig. A mélységi távolságokból számolom, hogy a sarokpont felé mekkora $t$ paraméternél éri el a síkot, és a szomszédos pontot $bold(N) + t (bold(C) - bold(N))$-re cserélem.


== Numerikus hibák csökkentése

= Mintázat

A Dotted és Patterned görbéknél mintázatot is számolok, és a mintázatoknál két irányba tudok elmenni. Az egyik, hogy az egész mintázatot képernyőtérben számolom, azaz a minták távolságát pixelekben adom meg. Ennek a módszernek az az előnye, hogy akármilyen közel megy a kamera a görbéhez, a minták közötti távolság a képernyőn állandó marad, így a görbe nem tűnhet el két minta között. A problémája az, hogy kis kameramozgásnál is drasztikusan elmozdulhatnak a minták (@screen_space_pattern). Ennek az az oka, hogy az ívhosszat a görbe elejétől mérem: ha a görbe eleje a vetítés után kicsit elmozdul vagy megnyúlik, akkor a mintázat a görbe teljes hosszán eltolódik, és ez az eltolódás a görbe vége felé halmozódik.

#figure(
  image("images/overlay_50.png",width:90%),
  caption: [Minimális kameramozgatással is drasztikusan változhat a mintázatok helye]
) <screen_space_pattern>

Az utóbbi miatt egy másik megoldást implementáltam, ahol a minták távolságát világtérben adom meg. Így ahelyett, hogy a kamera mozgásával egyre több vagy kevesebb minta lenne a görbén, a minták összenyomódnak vagy széthúzódnak. Ennek a módszernek az a hátránya, hogy nem alkalmas olyan esetekre, amikor a kamera nagyon közel kerül a görbéhez, és éppen két minta közé esik. Abban az esetben sem ideális, ha nem akarunk minden görbénél külön mintatávolságot megadni. Cserébe mozgás közben stabilabb a mintázat, azaz nem mozdulnak el a mintázatok drasztikusan mozgás közben.

== Ívhosszak számolása

Mivel a görbét mintavételezem, és törtvonallal közelítem, ezért elég minden mintavételi ponthoz kiszámolnom az ívhosszat. Ennek a feladatnak egy triviális megoldása, hogy sorban végigmegyek a szegmenseken, és összeadom a hosszukat. Mivel a lehető legtöbb munkát a GPU-n szeretném végezni, és a görbék felbontása változó, ezért más módszert kell használnom.

Két görbetípusnak van mintázata, a Dotted és a Patterned görbének. A Patterned görbénél egy minta hosszát is megadhatom, ami képernyőtérben, pixelben értendő. Így a Dotted görbénél elég világtérben kiszámolni az ívhosszat, míg a Patterned görbénél világtérben és képernyőtérben is szükségem van rá.

Először minden szegmens hosszát kiszámolom. Világtérben ez a két szomszédos mintavételi pont távolsága:

$ l_i = |bold(P)_(i+1) - bold(P)_i|. $

Képernyőtérben ugyanezt a pixelbe vetített pontokkal számolom. A vetített hossz azonban nagyon elfajulhat: ha a szegmens egyik végpontja a közeli sík mögé kerül, a vetített hossza a végtelenhez tarthat (@long_screen_space_segment). Ezért ha a szegmens teljesen a közeli sík mögött van, akkor a képernyőtérbeli hosszát nullának veszem, ha pedig csak az egyik végpontja, akkor a szegmenst a közeli síkra vágom, és a vágott szegmens vetített hosszával számolok. Az oldalsíkokra szándékosan nem vágok: a képernyőn kívüli részek is beleszámítanak a képernyőtérbeli ívhosszba, így a mintázat nem ugrik el, amikor a görbe egy része kicsúszik a képből. Vágás után a képernyőtérbeli hosszt ugyanúgy kezelhetem, mint a világtérbelit.

#figure(
  image("images/length_towards_infinity.png",width:90%),
  caption: [Ha nem vágom el a szegmenst a közeli síknál, akkor a hossza a végtelenhez tarthat]
) <long_screen_space_segment>

Ha ezekre a hosszakra lefuttatok egy prefix sum műveletet, akkor megkapom az adott ponthoz tartozó ívhosszat:

$ s_i = sum_(j < i) l_j. $

Az összeg exclusive, vagyis a görbe első pontjában az ívhossz nulla. Erre a parallel prefix sum algoritmust használom, pontosabban annak szegmentált változatát (segmented parallel prefix sum). Mivel az összes görbe ívhosszát egy tömbben tárolom, a szegmentálással érem el, hogy két, nem összekapcsolt görbe ne legyen hatással egymás ívhosszaira: az összeg minden olyan görbe elején újraindul, amely nem kapcsolódik az előzőhöz, az összekapcsolt görbéken pedig folytatódik (@len_sum).

#figure(
  image("images/len_sum.png",width:90%),
  caption: [Görbe ívhosszának kiszámítása az adott pontban]
) <len_sum>

== Mintázatok kiszámolása

A minták középpontjai a világtérbeli ívhossz mentén egyenletesen helyezkednek el: a $k$-adik minta középpontja az $s = k dot d$ ívhossznál van, ahol $d$ a mintatávolság. Összekapcsolt görbéknél az ívhossz a görbék között folytatódik, ezért a mintázat is folytonos marad az illesztéseknél. Egy görbe azokat a középpontokat kapja meg, amelyek a görbe első és utolsó pontjának ívhossza közé esnek. Ha

$ N(s) = cases(floor(s \/ d) + 1 & "ha" s > 0, 0 & "különben,") $

akkor egy görbe mintáinak száma $N(s_"utolsó") - N(s_"első")$. Ezt minden görbére párhuzamosan kiszámolom, majd a darabszámokra egy exclusive prefix sumot futtatok, így megkapom, hogy a görbe mintái hányadik helytől kezdődnek a közös mintatömbben, a tömb utolsó eleme pedig az összes minta száma (@pattern_count).

Az indexeket azért prefix summal számolom, és nem atomikus számlálóval foglalok helyet a mintáknak, mert így a minták sorrendje a tömbben determinisztikus, és megegyezik a görbék sorrendjével. A Patterned görbénél erre azért van szükségem, hogy kirajzoláskor az egymás melletti görbék mintái a tömbben is egymás mellett legyenek, így egy görbe pixelénél a szomszédos minták a szomszédos indexeken találhatók. A Dotted görbénél a minták sorrendje a kirajzolás sorrendje is. Mivel az élsimítást alpha blendinggel oldom meg, és abban az esetben ha a keverés nem sorrendfüggetlen, a minták sorrendje képkockáról képkockára változna, akkor az egymást fedő minták szélei vibrálnának.

#figure(
  image("images/pattern_count.png",width:90%),
  caption: [A görbénkénti mintaszámból prefix sum adja a görbe első mintájának indexét és a minták teljes számát]
) <pattern_count>

Ezután minden mintához megkeresem, melyik szegmensre esik. Mivel az $s_i$ ívhosszak egy görbén belül monoton nőnek, ezt bináris kereséssel teszem a görbe mintavételi pontjai között. A megtalált szegmensen belül a világtérbeli ívhossz alapján interpolálom a képernyőtérbeli ívhosszat, és ezt tárolom el a minta helyeként. Görbénként több szál dolgozik, mindegyik a görbe mintáinak egy részét számolja.

A mintatömb méretét viszont nem tudom a GPU-n meghatározni. A GPU-n nem tudok memóriát foglalni, a buffert előre, a CPU-n kell lefoglalnom. A pontos mintaszámot a GPU számolja ki, ennek visszaolvasása viszont várakoztatná a CPU-t a GPU-ra, ami pont azt a szinkronizációt vezetné be, amit el szeretnék kerülni. Ezért a CPU-n felülről becsülöm, hogy egy görbének legfeljebb hány mintája lehet. Mivel ezt minden alkalommal újra kell számolnom, amikor egy görbe alakja vagy mintatávolsága változik, a becslésnek gyorsnak kell lennie: nem értékelhetem ki a görbét, és nem számolhatok ívhosszat.

A felső becsléshez a Bézier-görbe ívhosszát a kontrollpoligon hosszával becsülöm (@upper_bound). A harmadfokú görbe deriváltja $bold(B)'(t) = 3 sum_(i=0)^2 b_(i,2)(t) bold(d)_i$, ahol $bold(d)_i = bold(P)_(i+1) - bold(P)_i$. A háromszög-egyenlőtlenség és $integral_0^1 b_(i,2)(t) dif t = 1/3$ miatt

$ L = integral_0^1 |bold(B)'(t)| dif t <= 3 sum_(i=0)^2 |bold(d)_i| integral_0^1 b_(i,2)(t) dif t = |bold(d)_0| + |bold(d)_1| + |bold(d)_2|. $

Egy $L$ hosszú szakaszra legfeljebb $floor(L \/ d) + 1$ olyan pont eshet, amelynek ívhossza $d$ többszöröse, ezért egy görbe mintáinak száma legfeljebb

$ floor((|bold(d)_0| + |bold(d)_1| + |bold(d)_2|) / d) + 1. $

Ehhez görbénként csak három vektor hosszát kell kiszámolnom, amit a görbéken párhuzamosan végzek. A becslések összegét kettő hatványára kerekítem, és ekkora mintatömböt foglalok. Csak akkor foglalom újra, ha a becslés már nem fér el benne, vagy a negyedére csökken, így a buffer nem változik minden kis módosításnál.

#figure(
  image("images/upper_bound.png",width:90%),
  caption: [A Bézier-görbe ívhosszát felülről becsüli a kontrollpoligon hossza]
) <upper_bound>

== Görbe-koordinátarendszer kialakítása
- törések kezelése
- SDF (megemlíteni, hogy lehet textúrázni)
- Csillag

= Összekapcsolt görbék

= Mérések


= Hibák

== Összefoglalás

= Fejlesztési lehetőségek

== Mesh shader

== Compute raster

== "Adaptív" felbontás

// További részletek a @intro -ben és a @telepítés -ben.

// #lorem(30)

// == Telepítés <telepítés>

// #lorem(10)

// Rendszerkövetelmények:
// - Számítógép
//   - Processzor
// - Billentyűzet

// Lépések:
// + Bekapcs
// + Kikapcs

// == Felhasználói felület

// #lorem(30)

// #figure(
//   image("images/elte_cimer_szines.png",width:30%),
//   caption: [elte címer]
// ) <cimer>

// #lorem(30)

// Lásd @cimer.

// #lorem(500)

// = Fejlesztői dokumentáció: Elméleti háttér

// Képletek $a/b+sqrt(5)$
// $
// sum_nabla^pi (1/(1/alpha(x)+k) + 1)
// $

// Idézés: "asd"


// = Fejlesztői dokumentáció: Algoritmusok

// Használj tetszőleges typst package-et algoritmusokhoz, ami tetszik.


// = Fejlesztői dokumentáció: Implementáció

// #figure(
// ```cpp
// for(int i = 0; i < sqrt(n); i++)
// {
//   std::cout << i << std::endl;
// }
// ```,
// caption: [Forráskód]
// )

// #lorem(40)

// = Tesztelés

// = Összefoglalás

// Források: @harry és @electronic.

// == Továbbfejlesztési lehetőségek

// Van néhány @wwdc-network és @plaque.

#bibliography("bib.yaml")

//==================================
#set heading(numbering: none)

= Appendix

== Mesterséges intelligencia felhasználása

#lorem(40)

== Saját hozzájárulás

#lorem(40)

== Rezümé

#lorem(40)