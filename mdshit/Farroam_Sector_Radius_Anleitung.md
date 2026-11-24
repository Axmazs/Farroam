# Farroam: Sektorgroesse unabhaengig von der Grafik

Diese Erweiterung baut auf dem laufenden Basic-Economy-Stand auf. Sie ersetzt die Groesse aus der PNG durch Sektordaten, zeichnet einen dynamischen Rand und passt die Kamera an. Es bleibt vorerst eine aktive Map; mehrere Sektoren und Reisen zwischen ihnen folgen als eigener Schritt.

## Die Werte

| Feld in SectorData | Standard | Bedeutung |
| --- | --- | --- |
| Minimum Map Radius Km | 60 | Kleinster Kartenradius, auch bei wenigen Objekten |
| Spawn Radius Km | 120 | Maximaler Abstand neuer KI-Schiffe und Stationen vom Sektormittelpunkt |
| Border Padding Km | 10 | Abstand des Kartenrandes zur aeussersten registrierten Objektposition |
| Center | `(0, 0, 0)` | Fester Mittelpunkt in Metern |
| Sector Id | `sector_01` | Kennung fuer den spaeteren Aufbau mehrerer Sektoren |

Die innere Flaeche von 0 bis 60 km ist erlaubt. Auch zwischen 60 und 120 km duerfen Stationen entstehen. Der Spawn-Radius vergroessert sich nicht, wenn die Karte waechst.

Der Rand wird so berechnet:

```text
Kartenradius = max(bisheriger Radius,
                  Mindestradius,
                  Abstand der aeussersten Objektposition + Randabstand)
```

Ein Objekt bei 120 km braucht daher mindestens 130 km Kartenradius. Fliegt ein Spieler auf 150 km hinaus, waechst die Karte auf mindestens 160 km. Der Mittelpunkt bleibt fest. Beim Zurueckfliegen schrumpft die Karte nicht automatisch. Die Grenze ist eine Darstellungsgrenze, keine Wand und keine Grenze der Spielwelt.

Abstaende beziehen sich auf die Datenpositionen der Objekte. Die bisherigen Marker haben im Simulationsmodell noch keine koerperliche Ausdehnung.

## Dateien einbauen

1. Den laufenden Test beenden.
2. `sector_data.gd` und `sector_camera_2d.gd` als neue Skripte in dein Projekt uebernehmen.
3. Die vorhandene `economy_map_2d.gd` an ihrem bisherigen Ort durch die neue Version ersetzen. `economy_overlay.gd` muss weiterhin im selben Ordner liegen. Der Root deiner Map behaelt das Map-Skript.
4. Den bestehenden **Camera2D-Node** der Map auswaehlen und ihm `sector_camera_2d.gd` als Skript zuweisen. Das ersetzt an diesem Node das bisherige Kamera-Skript. Die Kamera bleibt eine Camera2D.
5. Am Map-Root im Inspector beim neuen Feld **Sector** eine **New SectorData** erstellen. Aufklappen und die Werte 60, 120 und 10 eintragen beziehungsweise ueberpruefen.
6. Szenenzuweisungen fuer Freighter, Mine, Depot und ihre Marker bleiben wie im Economy-Test. Counts werden weiterhin am Map-Root eingestellt.
7. Map-Szene speichern und ueber ihren Tab mit **F6** starten.

Wenn Sector leer bleibt, erzeugt das Map-Skript beim Start eine Resource mit diesen Standardwerten. Eine Inspector-Resource macht die Einstellungen vor dem Start editierbar. Jede Map-Instanz verwendet eine eigene Kopie.

Der alte `SectorBorderSprite` kann in der Szene bleiben. Das neue Map-Skript blendet ihn aus. Sein Bild, seine Skalierung und sein Rechteck begrenzen weder Spawnpunkte noch Kamera. Der neue Kreis wird im Map-Skript gezeichnet.

## Geschwindigkeit und Einheiten

Eine Einheit in ShipData.position und StationData.position entspricht jetzt einem Meter. Die 2D-Darstellung verwendet X und Z als Kartenachsen. Damit lassen sich dieselben Weltpositionen spaeter auch in 3D benutzen.

Geschwindigkeiten werden durch das vorhandene Bewegungsskript damit als Meter pro Sekunde interpretiert:

| Speed | Entspricht | 120 km Strecke |
| --- | --- | --- |
| 180 | 0,18 km/s | etwa 667 Sekunden |
| 6000 | 6 km/s | 20 Sekunden |

Fuer einen kurzen Economy-Test in der groesseren Welt kannst du in der ShipData der Freighter-Szene **Speed = 6000** setzen. Das Sektorpaket aendert die Geschwindigkeitswerte nicht automatisch.

Beim Start erzeugt die Map die Objektpositionen neu. Die Zahl 120 ist ein Radius; der vollstaendige Spawn-Bereich hat 240 km Durchmesser.

## Kamera und Marker

- In der Gesamtansicht folgt die Kamera dem wachsenden Radius und zoomt passend heraus.
- Nach manuellem Hineinzoomen bleibt dein Zoom erhalten. Die Kamera aktualisiert weiterhin ihre erlaubten Zoom- und Pan-Grenzen.
- Mit dem Mausrad ganz herauszoomen schaltet wieder auf die Gesamtansicht.
- Mausrad und mittlere Maustaste funktionieren wie bisher.
- **Closest View Size Km** an der Kamera bestimmt den kleinsten sichtbaren Ausschnitt; Standard sind 5 km.
- Die Sprite-Marker behalten trotz der grossen Welt ihre Bildschirmgroesse. Die bereits vorhandenen HUD-Ladebalken werden ohnehin in Bildschirmkoordinaten gezeichnet.
- **Show Spawn Guides** am Map-Root zeichnet zusaetzlich dezente Orientierungskreise fuer Mindest- und Spawn-Radius. Der helle aeussere Kreis ist die aktuelle Kartengrenze.
- Das Economy-Panel bleibt unveraendert. **B** blendet es aus, falls es einen Teil der Karte verdeckt.

## Andere Objekte und spaeterer Spieler

Die Map registriert die von ihr erzeugten Stationen, Frachter und statischen Raider-Marker automatisch beim Sektor. Zurueckbleibende Ressourcen werden beim Entfernen der Besitzer wieder abgemeldet.

Ein spaeterer Spieler mit ShipData laesst sich beim Eintritt in diesen Sektor anmelden:

```gdscript
map.track_entity(player.data)
```

Dabei stehen `map` und `player` fuer deine Referenzen auf diese Map und das Spielerschiff. Sobald sich `player.data.position` aendert, beruecksichtigt die Map die Position fuer ihren Radius. Beim Verlassen beziehungsweise Entfernen des Objekts wird es wieder abgemeldet:

```gdscript
map.sector.unregister_entity(player.data)
```

Die Datenregistrierung ist unabhaengig vom sichtbaren Marker. Fuer ein bewegtes Spielerschiff braucht es zusaetzlich dessen bisherige Marker-Anbindung. Diese Erweiterung fuegt noch keine Spielersteuerung hinzu.

## Stationsabstand

**Minimum Station Distance Km** am Map-Root ist zusaetzlich ein Wunschabstand zwischen Stationen; Standard sind 5 km. Er ist unabhaengig von den 10 km Randabstand. Falls bei extrem vielen Stationen nach 128 Versuchen kein passender Ort gefunden wird, verwendet der Spawner seine beste Kandidatenposition und meldet eine Warnung. Die Spawn-Grenze von 120 km bleibt dabei erhalten.

## Gepruefter Umfang

Mit Godot 4.6.3 getestet: Mindestradius, Spawn-Verteilung innerhalb der gesamten Scheibe, 10-km-Randabstand, wachsender Radius ohne automatisches Schrumpfen, feste Mitte, voneinander getrennte SectorData-Instanzen und PNG-Unabhaengigkeit.

Der Integrationstest prueft ausserdem registrierte Economy-Objekte, Kameranachfuehrung, manuellen Zoom, Cursorbezug beim Zoomen, konstante Marker-Skalierung, Hover-Erkennung und weiterlaufende Produktion, Verbrauch und Warenbilanz. Wie beim Economy-Test wird die nicht vorliegende originale ShipAI durch eine bewegte Testimplementierung ihrer Schnittstelle ersetzt. Die optische Kontrolle in deinem Projekt steht noch aus.
