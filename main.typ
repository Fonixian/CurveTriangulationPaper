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

== Jelenlegi módszerek

Háromdimenziós görbék megjelenítésére több módszert néztem meg. A módszereket három kategóriába soroltam, amik a vonalprimitív, SVG és a geometria generáláson alapuló módszerek. A jelenlegi módszereknél a következő szempontokat vizsgálom meg, ahhoz, hogy görbéket jelenítsek meg.
- Távolságtól független vastagság, azaz a görbe vastagságát meg lehet adni pixelekben.
- Változtatható vastagság, azaz meg lehet adni, hogy hány pixel legyen a vastagság.
- Megadható mintázatok, azaz nem csak egy színből áll, hanem lehet szaggatott, pontozott görbét is megjeleníteni.
- Működik térben, azaz nem csak egy síkban adható meg a görbe.
- Portabilitás
Vannak más feltételek is, mint a színek és átlátszóság kezelése, valamint az anti-aliasing és a teljesítmény, de ezekre csak néhány helyen fogok kitérni ebben a fejezetben.

=== Vonalprimitíven alapuló módszerek

- glLineStipple, ezzel meg lehetett adni egy tizenhat bites bitmaszkot és egy faktort, ami megadja a raszterizált mintázatot. Ennek a módszernek egy nagy hátránya az, hogy ez a legacy OpenGL fixed function pipeline része, amit már nem használnak. Az /*@vs_segment_curve*/ ábrán látható, hogyan nézhetett ki.
- VK_KHR_line_rasterization, gyakorlatilag a glLineStipple, de egy modern API része. CAD alkalmazásoknak lett hozzáadva bővítményként, ugyanúgy meg lehet adni egy bitmaszkot és egy faktort, de hozzá még meg is lehet adni vonalraszterizációs algoritmust is. Egy nagy hátránya az, hogy nem minden eszközön van implementálva, vagy legalábbis nincsen teljesen implementálva, lásd /*@amd_impl_table*/. Valamint az is egy probléma, hogy ez egy Vulkan-specifikus bővítmény.

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

- Vertex és fragment shader, a legegyszerűbb megoldás, ha csak kiszámoljuk a vertex shaderben, hogy egy adott pontnak milyen pixelkoordinátái vannak, majd a fragment shaderben az interpolált értékből kiszámoljuk, hogy melyik fragmenteket dobjuk el. Lehet látni az ábrán /*@gl_segment_curve*/, hogy a mintázat nem megfelelő, mert a szegmensek hossza nem egyezik meg a mintázat hosszával. Ezt ki lehet küszöbölni azzal, hogy CPU-n kiszámoljuk az adott ponthoz tartozó ívhosszát a görbének, de ezt potenciálisan minden frame-ben ki kell számolnunk, mert a mintázat screen space, de a kamera mozoghat, de ha kiszámoljuk, akkor a /*@vs_segment_curve*/ ábrához hasonló görbét kapunk.

//#figure(
//  image("images/gl_segment_curve_combined.png",width:100%),
//  caption: [Vertex és fragment shader használatával megjelenített szegmens és görbe.]
//) <gl_segment_curve>

Az /*@vs_segment_curve*/ ábrán lehetett olyan hibát látni, hogy a szaggatások a görbén mintha rossz irányba állnának meg keresztezik egymást a görbületnél. Ez azért fordul elő, mert a görbe szakaszokból áll és a szakaszok egyenesek, amikre a szaggatásos mintázat merőleges.

Valamint a vonalprimitíveknek van három nagy hátránya a görbék rajzolására, számomra.
- Nem garantált, hogy tudunk vonalvastagságot megadni, mert az eszközfüggő, a DX11-ben egyszerűen nincsen metódusunk a vonalvastagság megadására.
- A vertex és fragment shader szempontjából nincsen a vonalnak vastagsága, azaz tudunk adni értékeket, amik a hossz mentén interpolálódnak, de nem tudunk a szélesség mentén ugyanezt megadni. Ennek az eredménye az, hogy csak különböző szaggatásokat tudunk létrehozni, de nem tudjuk a görbe végét lekerekíteni.
- A vastag vonalak által létrehozott solid görbe nem szép /*@line_solid_curve*/, mivel nem nyúlnak túl a szegmensek két pont között.

//#figure(
//  image("images/vk_curve_thick_solid.png",width:80%),
//  caption: [Vastag görbe vonalprimitívekkel kirajzolva]
//) <line_solid_curve>

=== Vektorgrafika

Több interfész létezik GPU-val gyorsított vektorgrafikára, így Bézier-görbék megjelenítésére is, például az OpenVG és az NV_path_rendering. Ezek az interfészek SVG-útvonalak megjelenítésére szolgálnak, ezért az SVG-útvonalak teljes eszköztárát támogatják. Az SVG-ben a `stroke-dasharray` attribútummal szaggatott vagy pontozott vonalat adhatok meg: a `16 10` érték például 16 egység hosszú szakaszokat és 10 egység hosszú réseket rajzol, a `0 10` érték pedig kerek vonalvégek (`stroke-linecap="round"`) mellett pontokat. Egyetlen útvonalba több Bézier-görbét is felfűzhetek (`C` és `S` parancsok), és a mintázat ilyenkor az illesztéseken át folyamatosan halad tovább az útvonal ívhossza mentén.

Hátrányuk, hogy csak kétdimenziós megjelenítésre alkalmasak. Megkerülhetném ezt úgy, hogy a CPU-n kiszámolom a kontrollpontok képernyőkoordinátáit, de ez Bézier-görbéknél nem elég. A Bézier-görbék ugyan affin invariánsak, a 3D-s alkalmazások perspektív vetítése viszont nem affin. Vetítés után racionális Bézier-görbe kontrollpontjait kapom meg, amelyet ezek az interfészek nem támogatnak. Ezért két lehetőségem marad, pontok sorozataként adom meg a görbét, vagy de Casteljau-algoritmussal addig osztom kisebb Bézier-görbékre, amíg a hiba elég kicsi nem lesz. Az utóbbi módszerek sok CPU-időt igényelnek, mert minden képkockánál újra kell számolnom.

Emellett ezek az interfészek az ábra elemeit festőalgoritmussal rajzolják ki, ezért nem használnak mélységet, és nem kezelik azt az esetet, amikor két görbe takarja egymást. Az NV_path_rendering kezeli a mélységet, de ez az ábra síkjának mélységére vonatkozik, nem az benne lévő elemekre.

Ezeknek az interfészeknek egy másik problémája, hogy nem optimalizáltak változó geometria megjelenítésére. Affin transzformációkat, például forgatást és eltolást minimális költséggel végrehajthatok rajtuk. A kontrollpontok módosítása viszont jelentős költséggel jár.

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

Mivel a grafikus API-k által nyújtott vonalprimitívek nem elegendőek vastag görbék megjelenítésére, ezért manuálisan kell nekem előállítani a görbét, de erre több módszer is létezik. Az utóbbi módszereket lehet kettő kategóriába az egyik amely geometriával próbálja legjobban közelíteni a görbét. A másik csak közelíti a görbét és pixel shader használatával éri el a görbe alakját, úgy, hogy eldob fragmenteket. 

Az egyik legegyszerűbb módszer a geometria shader használata, amivel a bejövő görbének két szomszédos pontjából elő lehet állítani egy négyszöget, majd a pixel shaderrel lekerekítem a sarkokat. Az utóbbi módszernél lehet geometria shader helyett csak vertex shader használni, például a különböző grafikus API-k által kínált instanced rajzolás parancsok használatával, ahol "ugyanazt" a négyszöget rajzoljuk ki más más eltolásokkal.

Valamint az utóbbi módszernek egy másik változata, az, hogy ahelyett, hogy pixel shaderben kerekítenénk le a sarkokat. Ahelyett négyszögek helyett bonyolultabb alakot használunk fel, egy kétdimenziós kapszulát, ahol a végpontokban már lekerekítettek a görbe szakaszok vége.

A két módszerrel olyan problémám van, hogy nem kezelik jól az átlátszóságot, mivel a két egymás melletti szegmense a görbének fedi egymást. Ezért a görbén megjelennek pontok, ahol kétszer adódik hozzá a görbe színe az alpha blending során. Valamint a görbéknél gyakran az anti-aliasing alpha blendinggel történik, emiatt akkor is meg tudnak jelenni artifactok, ha a görbe nem átlátszó, ha anti-aliasingoljuk alpha blend használatával.

Az utóbbi módszerek hibáinak a csökkentésére szokásos háromszögelni a szegmensekre osztott görbét. Ilyenkor el tudjuk kerülni, hogy két egymást követő szegmens egymást fedje. Ezt implementálja ImGui a CPU-n, valamint Rye Terrell a GPU-n, az utóbbival az a probléma, hogy a háromszögelés egyszerű, valamint nem minden esetet kezel le.


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

== Bézier görbék
// https://onlinelibrary.wiley.com/doi/10.1155/2013/171392
// https://books.google.hu/books?id=YmQy799flPkC&pg=PA264&redir_esc=y#v=onepage&q&f=false
// https://books.google.hu/books?id=TAYw3LEs5rgC&pg=PA404&redir_esc=y#v=onepage&q&f=false


Munkám során Bézier-görbék megjelenítésével foglalkozom, azon belül is a harmadfokú Bézier-görbékkel. Ezt a döntést három érv indokolja:
- A Bézier-görbék a legelterjedtebbek a CAD- és a grafikai tervezőszoftverekben.
- Az SVG specifikációja a másod- és a harmadfokú Bézier-görbéket tartalmazza.
- Több más görbe is átírható Bézier-görbévé: tetszőleges n-ed fokú polinom felírható n-ed fokú Bézier-görbeként, a harmadfokú Catmull-Rom spline, Hermite spline és B-spline szakaszai pedig pontosan megegyeznek egy-egy harmadfokú Bézier-görbével.

A Bézier-görbéknek további hasznos tulajdonságaik is vannak:
- Konvex burok tulajdonság: a görbe minden pontja a kontrollpontok konvex burkán belül van.
- Affin invariancia: affin transzformáció után a görbe megegyezik a transzformált kontrollpontokból kapott görbével.
- Végpont-interpoláció: a görbe kezdőpontja az első, végpontja az utolsó kontrollponttal egyezik meg.
- Fokszámemelés: egy n-ed fokú Bézier-görbe pontosan felírható n+1-ed fokú Bézier-görbeként.

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

== Görbe változatok

Három görbe típust különbözetek meg kirajzolás szempontjából, Solid, Dotted és Patterned. Mind a háromnál adott a görbe végeinél a kupakok (Round, Square, Butt, Triangle In, Triangle Out), az interpolálandó színek, szélesség, valamint az hogy csatlakozzanak-e az elöző görbéhez.
- Solid: A görbének csak kupakjai vannak.
- Dottted: Megadhatóak, hogy milyen távol legyenek egymástol a pontok és egy pont a kettő megadott kupakból áll.
- Patterned: A görbét szegmensekre osztom és a szegmenseknek adok kupakokat.

A görbe változatokra azért volt szügségem, mert minimalizálni szeretném az elvégzett munkát. Páldául a Patterned görbénél szügséges nekem a görbe ívhossza de a Solid-nál nincs rá szükségem. Valamint a Dotted görbénél nincs szügség a görbe előállítására mivel elég csak kiszámolni a mintázatok helyét és négyszögeket rajzolni.

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