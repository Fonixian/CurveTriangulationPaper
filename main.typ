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
  show raw: set par(leading: 0.75em)
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

Munkám során ahhoz hogy a Bézier görbéket megjlenítsem a vonal primitívet cserélem le, ez alatt azt értem, hogy nem a grafikus API-k által kínált vonal primitíveket használnom. Például: GL_LINE_STRIP, D3DPT_LINESTRIP, VK_PRIMITIVE_TOPOLOGY_LINE_STRIP
Az utobbira azért van szügség, mert a vonal primitíveken erős megkötések vannak, például a grafikus API-k nem garantálják, hogy a vonal szélessége megváltoztatható legyen, a DX11-ben nem is lehet megadni a széleségét és még nem is beszéltünk arról az estről, amikor mintázatot szeretnénk futtatni a görbe mentén. Valamint mintázatokat sem támogatnak alapból a grafikus API-k.

Ez egy olyan probléma, amire több megoldás is létezik, de általában mindegyiknak megvan a saját hátránya vagy nem támogatja au összes funkciót, ami számomra szügséges.

== Jelenlegi módszerek

A jelenlegi módszereknél a következő szempontokat vizsgálom meg, ahhoz hogy görbéket jelenítsek meg
- Távolságtól független vastagság, azaz a görbe vastagságát meg lehet adni pixelekben.
- Változtatható vastagság, azaz meg lehet adni, hogy hány pixel legyen a vastagság.
- Megadható mintázatok, azaz nem csak egy színből áll, hanem lehet szaggatott, pontozott görbét is megjeleníteni.
- Működik térben, azaz nem csak egy síkban adható meg a görbe.
Valamint vannak más feltételek is mint a színek és átlászőság kezelése, valamint az anti-aliasing és a teljesítmény, de ezekre csak néhány helyen fogok kitérni ebben a fejezetben.

=== Vonalprimitíven alapuló módszerek

- glLineStipple, ezzel meg lehetett adni egy tizenhat bites bitmaskot, ami megadja, hogy a görbének melyik pixeleit rajzolja ki a rasterizer. Valamint meg lehetett adni egy factort, ami azt adta meg, hogy egy bit mennyi egymást követő pixelt érint. Ennek a módszernek egy nagy hátránya az, hogy ez a legacy OpenGL fixed function pipeline része, amit már nem használnak. Az @vs_segment_curve ábrán látható, hogy nézhetett ki.
- VK_KHR_line_rasterization, gyakorlatilag a glLineStipple de egy modern API része. CAD alkalmazásoknak lett hozzá adva bővítményként, ugyanúgy meg lehet adni egy bitmaskot és egy faktort de hozzá még meg is lehet adni vonal raszerizációs algoritmust is. Egy nagy hátránya az, hogy nem minden eszközön van implementálva vagy legalábbis nincsen teljesen implementálva lásd @amd_impl_table. Valamint az is egy probléma, hogy ez egy Vulkán specifikus bővitmény.

#figure(
  image("images/vk_segment_curve_combined.png",width:100%),
  caption: [VK_KHR_line_rasterization (SmoothLine) használatával megjelenített szegmens és görbe.]
) <vs_segment_curve>

#figure(
  table(
    columns: 2,
    [Algoritmus], [Implementált],
    [bresenhamLines], [Igen],
    [rectangularLines], [Nem],
    [smoothLines], [Nem],
    [stippledBresenhamLines], [Igen],
    [stippledRectangularLines], [Nem],
    [stippledSmoothLines], [Nem]
  ),
  caption: [AMD Radeon(TM) 610M (2022) által támogatott algoritmusok],
) <amd_impl_table>

- Vertex és fragment shader, a legegyszerűbb megoldás ha csak kiszámoljuk, a vertex shaderben, hogy egy adott pontnak milyen pixel koordinátái vannak, majd a fragment shaderben az inetrpolált értékből kiszámoljuk, hogy melyik fragmenteket dobjuk el. Lehet látni az ábrán @gl_segment_curve, hogy a mintázat nem megfelelő, mert a szegmensek hossza nem egyezik meg a mintázat hosszával. Ezt ki lehet küszöbölni azzal, CPU-n kiszámoljuk az adott ponthoz tartózó ívhosszát a görbének, de ezt potenciálisan minden frameben ki kell számolnuk, mert a mintázat screen space, de a kamera mozoghat, de ha kiszámoljuk akkor @vs_segment_curve hoz hasonló görbét kapunk.

#figure(
  image("images/gl_segment_curve_combined.png",width:100%),
  caption: [Vertex és fragment shader használatával megjelenített szegmens és görbe.]
) <gl_segment_curve>

Az @vs_segment_curve ábrán lehetett látni olyan hibát látni, hogy a szaggatások a görbén mintha rossz irányba állnának meg keresztezik egymást a görbületnél. Ez azért fordul elő, mert a görbe szakaszokból áll és a szakaszok egyenesek, amikre a szaggatásos mintázat merőleges.

Valamint a vonal primitíveknek van három nagy hártánya a görbék rajzolására, számomra.
- Nem garantált, hogy tudunk vonal vastagságot megadni, mert az eszköz függő, a DX11-ben egyszerűen nincsen metódusunk a vonal vastagság megadására.
- A veretex és fragment shader szempontjából nincsen a vonalnak vastagsága, azaz a tudunk adni értékeket, amik a hossz mentén interpolálodnak de nem tudunk a szélesség mentén ugyanezt megadni. Ennek az eredménye az hogy csak különböző szaggatásokat tudunk létrehozni, de nem tudjuk a görbe végét lekerekíteni.
- A vastag vonalak által létrehozot solid görbe nem szép @line_solid_curve, mivel nem nyúlnak túl a szegmensek két pont között.

#figure(
  image("images/vk_curve_thick_solid.png",width:80%),
  caption: [Vastag görbe vonal primitívekkel kirajzolva]
) <line_solid_curve>

=== Vector grafika

Több interfész is van GPU áltar gyorsított vektorgrafika és ez által Bézier görbék megjelenítésére is, például OpenVG és NV_path_rendering (OpenGL). Mivel ezeket SVG-k megjelenítésére készítették ezért a görbék mindent tudnak mint az SVG görbék. A hátrányuk az, hogy 2D-ben működnek, egy megoldás lenne az hogy kiszámolom a pontokat a CPU-n hogy hol legyenek a képenyőn, de ez a kontroll pontokkal megadott Bézier görbének nem elég, mert az igaz, hogy a Bézier görbék affin invariánsak, de a 3D-s alalmazásokban használt perpektív vetítés nem affin ezért vagy pontok sorozatát kell megadni, vagy addig kell a kettéválasztás algoritmussal több kissebb Bézier görbére osztani amig elég kicsi nem lesz a hiba. Az uttobbi módszer CPU intenzív tud lenni, mert minden frame-ben újra kell számolni. Valamint ezek az interfészek nem használják a mélységet hanemfestő algoritmussal működnek.

// TODO kép

=== Generált geometria


// Jelenlegi módszerek előnyökk hátrányok képek (forrás)
//- opengl 2.0 api
//- https://wwwtyro.net/2019/11/18/instanced-lines.html (Összehasonlítás) (solid)
//- VK_KHR_line_rasterization
//- https://github.com/ocornut/imgui/wiki/Pixel-Perfect-Rendering
//- https://developer.nvidia.com/nv-path-rendering
//- https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects///chapter-25-rendering-vector-art-gpu
//- http://artgrammer.blogspot.com/2011/07/drawing-polylines-by-tessellation.html
//- Elöző munkám


=== Vonal primitív alapú módszerek:
- glLineStipple, amivel meg lehetett adni egy 16 bites mintát és egy szorzót, a kettő adja meg, hogy milyen a mintázat és egy hoszz szorzót. Ezzel a módszerrel az a probléma, hogy ez a legacy fixed function pipile része az OpenGL specifikációnak és nem elérhető modern OpenGL-ben.
- VK_KHR_line_rasterization, egy modern módszer szaggatott vonalra, ahol meg lehet adni a vonal rasterizáicó algoritmusát is. Nem garantált, hogy működni fog az eszközön.

- Valamint mi is tudunk szaggatott szakszokat rajzolni egyszerűen, ha a vertex shaderben kiszámoljuk a vertexek poziciójat pixel koordináta rendszerben és a pixel shaderben meg felhasználjuk a szaggatás elkészítéséhez. Ezzel a módszerrel az a legnagyobb probléma, hogy a mintázat szakaszonként úrja kezdődik, ezért a mintázat nem folytonos a görbe mentén.

Az összes módszernél, abba a limitációba esünk, hogy a egyenesünknek nincsen szélessége azaz csak szaggatásből áll a mintázat és nem lehet pontozottat vagy nyilakat létrehozni.

== Bezier görbék

Miért Bezier görbéket használtam?

== Görbe változatok

Miért van több? Mi a különbség?
- Solid
- Dotted
- Patterned

= Geometria Generálás

Mivel a görbéket futás időben szerentém módosítani, emiatt nincs lehetőségem offline elkészíteni a háromszögelését. Mivel egy-egy görbénénél a felbontás előre megadott, azaz nem válzotik attől függöen, hogy milyen alakja van a görbének, ezért ez egy könnyen párhuzamosítható feladat.

Ha vesszek egy görbét, aminek a felbontása harminckettő, akkor az azt jelenti, hogy a Bezier görbe harminckettő helyen van kiértékelve és ezekből az értékekből harmincegy szegmenst kell létrehozni. Ahhot, hogy egy szegmens alakját meg tudjuk kapni, ahhoz elég csak négy pontot ismernünk, lásd @4point_segment. 


#figure(
  image("images/segment_from4point.png",width:80%),
  caption: [Egy szegment elő állításához csak négy szomszédos pont szükséges]
) <4point_segment>

== Segment Culling


== Numerikus hibák csökkentése

= Mintázat

== Screen space

== Stable in World space



== Görbe koordináta rendszer kialakítása
- törések kezelése
- SDF (megmelíteni hogy lehet tesztúrázni)
- Csillag

= Összekapcsolt görbék

= Mérések


= Hibák

== Összefoglalás

= Fejlesztési lehetőségek

== Mesh shader

== Compute raster

== "Adaptive" felbontás

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