# Farroam: Basic Economy

Dieser Stand verbindet eine Erzmine, Depots, Transportjobs und Frachter. Die Mine produziert Erz, Depots verbrauchen es und bestellen nach. Die Anzeige liest die Bestandsdaten und das gemeinsame Jobboard.

## Die sechs Skripte

| Datei | Verwendung |
| --- | --- |
| `station_ai.gd` | Vorhandenes Skript ersetzen. Inventarfunktionen und automatische Registrierung fuer die Anzeige. |
| `freighter_ai.gd` | Vorhandenes Skript ersetzen. Jobausfuehrung wie zuvor; direkte Jobboard-Referenz und Registrierung fuer die Anzeige sind enthalten. |
| `depot_ai.gd` | Vorhandenes Skript ersetzen. Nachbestellungen und zeitgesteuerter Verbrauch. |
| `mining_station_ai.gd` | Neues Skript am `Job`-Node der geerbten Mining-Station-Szene. |
| `economy_map_2d.gd` | Neues Skript fuer den Root deiner bestehenden Map-Szene; ersetzt dort die bisherige Map-Steuerung. |
| `economy_overlay.gd` | Im selben Ordner wie `economy_map_2d.gd` ablegen. Wird von der Map automatisch als CanvasLayer erzeugt. |

Die vorhandenen `station_data.gd`, `ship_data.gd`, `ship.gd`, `ship_ai.gd`, Simulationsmodi, Marker-Szenen und `job_board.gd` werden weiterverwendet. Bestehende Skripte an ihrem bisherigen Ort ersetzen, damit keine zweite gleichnamige globale Klasse entsteht.

## 1. Gemeinsame Voraussetzungen

- Autoload heisst genau `JobBoard` und verwendet dein `job_board.gd`.
- `ShipAI.initialize()` ruft weiterhin `job.initialize(self)` auf.
- `ShipAI` hat weiterhin `fly_to(destination: Vector3)`, `set_map_mode(map_open: bool)` und das Signal `arrived`.
- In `ShipData` stehen `cargo_capacity`, `cargo_amount`, `cargo_type`, `speed`, `position` und die bisherigen Flugdaten.
- In `JobData` stehen die beiden Stationsziele sowie `delivered_amount` und `get_remaining_amount()` aus dem vorigen Schritt.
- Kamera und Map verwenden den bestehenden Kreis-Node `SectorBorderSprite`.

Fehlt in `ShipData` noch die Warenart, diese Variable ergaenzen:

```gdscript
@export var cargo_type: String = ""
```

## 2. Mining-Station erstellen

1. Aus `station.tscn` eine **New Inherited Scene** erstellen und als `mining_station.tscn` speichern.
2. Root behaelt `station_ai.gd`. An den bestehenden Child-Node **Job** kommt `mining_station_ai.gd`.
3. Am Root bei **Data** eine eigene StationData einstellen. Bei einer geerbten vorhandenen Resource zuerst im Resource-Menue **Make Unique** waehlen. **Local To Scene** aktivieren.
4. Daten setzen:

| Feld | Startwert |
| --- | --- |
| Station Type | `mining_station` |
| Cargo Capacity | `100` |
| Stock | `ore: 0` |

5. Am Job-Node **Ware Type = ore**, **Production Amount = 10**, **Production Interval = 2**.

Das ergibt 10 Erz alle 2 Sekunden. Ist das Lager voll, wird nur noch die passende Menge eingelagert. Es wird kein unsichtbarer Ueberhang angesammelt.

## 3. Depot einstellen

Die geerbte Depot-Szene behaelt `station_ai.gd` am Root und verwendet die neue Version von `depot_ai.gd` am Job-Node.

Am Root eine eigene StationData wie oben beschrieben verwenden:

| Feld | Startwert |
| --- | --- |
| Station Type | `depot` |
| Cargo Capacity | `100` |
| Stock | `ore: 30` |

Am Job-Node:

| Feld | Startwert |
| --- | --- |
| Minimum Stock | `ore: 60` |
| Check Interval | `2` |
| Consumption Per Tick | `ore: 4` |
| Consumption Interval | `3` |

In **Minimum Stock** fuer diesen Test die alte Zeile `food` entfernen, falls sie in deiner Szene gespeichert ist. Ein Dictionary-Wert in der Szene kann den neuen Skript-Standard ueberschreiben.

Das Depot verbraucht maximal 4 vorhandene Erz-Einheiten alle 3 Sekunden. Der Bestand wird nie negativ. Unter 60 Erz bestellt es die fehlende Menge nach. Ein offener oder angenommener Auftrag derselben Warenart verhindert doppelte Bestellungen dieses Depots. Verbrauch waehrend eines laufenden Auftrags wird mit einer spaeteren Bestellung ausgeglichen.

Das neue Map-Skript setzt **Supply Station** beim Erzeugen automatisch auf eine Mine. In der Depot-Szene muss deshalb keine externe Stationsinstanz eingetragen werden.

## 4. Frachter einstellen

`freighter_ai.gd` bleibt am **ShipAI/Job**-Node deiner geerbten Freighter-Szene.

| ShipData-Feld | Startwert |
| --- | --- |
| Cargo Capacity | `30` |
| Cargo Amount | `0` |
| Cargo Type | leer |
| Speed | `180` |

Jobtyp im Frachter bleibt `hauling`. Der Frachter wartet auf Waren oder Lagerplatz und kann einen Auftrag mit mehreren Touren erfuellen. Ein- und Ausladen sind vorerst sofort.

## 5. Map verbinden

1. `economy_map_2d.gd` und `economy_overlay.gd` nebeneinander ablegen, z. B. in `2D_Map`.
2. Am Root deiner bestehenden Map-Szene die bisherige Map-Steuerung durch `economy_map_2d.gd` ersetzen. Der Kreis und die Kamera bleiben Child-Nodes der Map.
3. Im Inspector die Szenen zuweisen:

| Inspector-Feld | Szene |
| --- | --- |
| Freighter Scene | Logische `freighter.tscn` mit ShipData und ShipAI |
| Freighter Marker Scene | Sichtbare `freighter_marker.tscn` mit dem bestehenden Marker-Skript |
| Depot Scene | Logische `depot.tscn` mit StationAI und Depot-Job |
| Depot Marker Scene | Sichtbare `depot_marker_2d.tscn` |
| Mining Station Scene | Logische `mining_station.tscn` mit StationAI und Mining-Job |
| Mining Station Marker Scene | Sichtbare `mining_station_marker_2d.tscn` |

Die drei logischen Szenen sind erforderlich. Ohne Marker-Szenen zeichnet die Anzeige einfache Ersatzsymbole. Die Felder **Depot Scene** und **Mining Station Scene** meinen jetzt die logischen Objekte; dort waren im alten Spawner noch Marker zugewiesen.

4. **Mining Station Count = 1**, **Depot Count = 2**, **Freighter Count = 2**, **Raider Count = 0** setzen.
5. Fuer diesen Test die Map die Objekte erzeugen lassen. Bereits manuell platzierte Teststationen und Frachter aus dieser Testszene entfernen, damit sie nicht zusaetzlich teilnehmen.
6. Szenen speichern, Map-Tab auswaehlen und **F6**.

Jede erzeugte Station und jedes Schiff bekommt eine eigene Datenkopie. Stationspositionen setzt die Map einmalig und verwendet dieselben Positionen fuer Marker, Hover-Erkennung und Flugziele.

## Anzeigen und Bedienung

- Maus ueber einer Station: Waren und Mengen, gesamte Lagerbelegung sowie Produktions- oder Verbrauchstakt.
- Rechts: Jobtyp, Ware, Abhol- und Lieferstation, offen/angenommen, gelieferte Menge und zugeordneter Frachter.
- Ueber jedem Frachter: Ladebalken und `Menge/Kapazitaet`.
- Rechts darunter: Frachterladung und aktueller Arbeitsschritt.
- **B**: rechtes Panel ein-/ausblenden, falls es einen Marker verdeckt.
- **1 / 2**: vorhandenen No-Map-/2D-Modus waehlen. Produktion und Verbrauch laufen weiter. Die vorhandenen Simulationsskripte steuern den Moduswechsel.

Die gemeinsamen Registrierungsgruppen `economy_stations` und `economy_ships` setzen die Skripte selbst. Deine bisherigen Gruppen an den Marker-Szenen muessen dafuer nicht geaendert werden. Die UI schreibt keine Inventardaten.

## Den Test lesen

1. Die Mine steigt alle 2 Sekunden um bis zu 10 Erz.
2. Die Depots beginnen mit 30 Erz, melden Bedarf bis 60 und verbrauchen je 4 Erz alle 3 Sekunden.
3. Zwei Depots koennen gleichzeitig je einen offenen Erz-Job haben. So erhalten beide Frachter Arbeit.
4. Bei Abholung sinkt der Minenbestand und steigt die Frachterladung um dieselbe Menge.
5. Bei Lieferung sinkt die Frachterladung und steigt der Depotbestand um dieselbe Menge.
6. Jobs verschwinden erst nach vollstaendiger Lieferung vom Board. Weiterer Verbrauch erzeugt spaeter neue Jobs.

## Gepruefter Umfang

Mit Godot 4.6.3 wurden Erzeugung logischer Szenen samt eigenen Daten, zeitgesteuerte Produktion und Verbrauch, zwei aktive Frachter, Inventar- und Kapazitaetsgrenzen, HUD-Texte, Hover-Erkennung und Sichtbarkeit getestet. Die Bilanz aus erzeugtem Erz, verbrauchtem Erz und Restbestaenden blieb erhalten.

Die aktuellen ShipAI-/Marker-Dateien deines Projekts lagen nicht vor. Im Integrationstest uebernahm eine kleine bewegte Testimplementierung dieselbe ShipAI-Schnittstelle. Deine vorhandenen Flugmodi und die optische Darstellung in deiner Map muessen deshalb noch dort geprueft werden.

Preise, Geld, Handelspreissuche, Warenreservierung vor Abholung, Ladezeiten und Speicherung des Spielstands sind noch keine Bestandteile dieses Tests. Fuer die Nachversorgung wird derzeit die vom Spawner zugewiesene Mine verwendet.
