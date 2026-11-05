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

Egy sarok vertexei csak három ponttól függenek, ezért egyszerűbb a vertexek kiszámolásához nem a szegmenseket, hanem a sarkokat vennem. A sarkoknál négy plusz egy esetet különböztetek meg, és ezek befolyásolják a háromszögelést.
- Egyenes eset: amikor három egymást követő pont egy egyenesbe esik.
- Tompa szög: amikor a három egymást követő pont tompaszöget alkot. Ilyenkor a görbe szegmenseknél miter-csatlakozást alkalmazok.
- Hegyes szög: amikor a három egymást követő pont hegyesszöget alkot. Ilyenkor a görbe szegmenseknél bevel-csatlakozást alkalmazok, pontosabban olyan bevelt, amelyet a vonalvastagság felével eltolok.
- Overlap: ez az eset akkor fordul elő, amikor a görbe szakasza túl rövid az adott szög és vonalvastagság mellett. Ilyenkor a belső miter értéke túlnyúlna a szegmensen, és elrontaná a háromszögelést.
- Görbe vég: ez az eset akkor áll fenn, amikor a görbe utolsó pontját értékelem ki, és nincs három egymást követő pontom.



== Segment Culling


== Numerikus hibák csökkentése

= Mintázat

== Screen space

== Stable in World space



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