# Identifizierte Einschränkungen und Grenzen: Vision Pro, visionOS 26

## 1. Einschränkungen der Fußinteraktion

* **Keine native Fußerkennung in RealityKit**
  RealityKit stellt derzeit keine Fußerkennung bereit. Dadurch ist eine Umsetzung von Fußpedalen (z. B. Kick oder Hi-Hat) über Bilderkennung nicht möglich.

* **Kein Zugriff auf Kamerabilddaten**
  Der fehlende Zugriff auf das Rohbildmaterial der Kameras verhindert eine eigenständige Implementierung einer Fußerkennung.

* **Limitierte Eingabealternativen**
  * **Tastatur-Input** ist nur eingeschränkt nutzbar, da er Fokus benötigt, welcher häufig von anderen UI-Elementen belegt oder reserviert ist.
  * **SwiftUI Commands** benötigen zwar keinen Fokus, liefern jedoch keine Unterscheidung zwischen *Key Down* und *Key Press* Events. Diese Differenzierung ist jedoch essenziell, z. B. für die korrekte Abbildung eines Hi-Hat-Pedals.
  * **Simulation über einen Custom Game Controller** ist technisch möglich, stellt alleine jedoch für Endnutzer keine praktikable Lösung dar.

Lösungsansätze wären hier Anleitungen und Modelle von 3D-druckbare Pedal-Adaptern für gängige kommerzielle Controller zur Verfügung zu stellen. Wobei das beste Ergebnis wohlmöglich mit selbstgebauten Pedalen mittels Microcontrollern und Hall-Sensoren oder Piezo Discs.

## 2. Einschränkungen der Handerfassung

* Da das Spielen vollständig auf der Handerfassung basiert, müssen sich die Hände jederzeit im Sichtfeld der Kameras befinden.
  * Verdeckungen einer Hand durch die andere führen zu Erkennungsproblemen.
  * Schläge, die außerhalb des Sichtfelds ausgeführt werden – wie beim echten Schlagzeug üblich –, können nicht erkannt werden.
  * Damit die Hände zuverlässig erkannt werden, ist zudem gute Belichtung nötig.

Durch mehrere Nutzertests haben wir herausgefunden, dass kleinere Schlagzeuge hier deutlich bessere Ergebnisse liefern, die Hände so größtenteils im Sichtbereich der Kameras bleiben.

Eine weitere Alternative wäre es die Verwendung von PSVR2 Controller zu erforschen. Dies könnte sowohl das Problem der Handerkennung sowie der Latenz lösen.

## 3. Fehlendes haptisches Feedback

* Es existiert keinerlei physische Rückmeldung (Haptik oder Widerstand) bei erfolgreichen Schlägen, was das Spielgefühl deutlich von einem realen Instrument unterscheidet.

## 4. Limitierungen der Kollisionsdetektion in RealityKit

* **Eingeschränkte Kollisionsinformationen**
  Die native Collision Detection von RealityKit liefert, für an die Hand befestigte Entities, keine Informationen über die Richtung der Kollision oder die Aufprallgeschwindigkeit (Velocity).
  Dadurch ist sie nicht ausreichend geeignet, um ausschließlich Schläge auf das Trommelfell zu erkennen oder die Schlagsstärke realistisch zu berechnen.
  Kollisionen werden nicht kontinuierlich geprüft. Bei schnellen Bewegungen kann dies zu *Tunneling*-Effekten führen, bei denen Kollisionen vollständig verpasst werden.

* **Alternative Lösung**
  Eine manuelle Velocity-Berechnung in Kombination mit Raycasts aus RealityKit stellt eine deutlich zuverlässigere Alternative dar und liefert in der Praxis bessere Ergebnisse.

## 5. Audio Latenz

* **Vorhandene Latenz**
  Eine gewisse Latenz wird technisch bedingt immer vorhanden sein. Dies ist für Schlagzeugspieler deutlich bemerkbar. Für E-Schlagzeugspieler war dies, aufgrund der bei E-Schlagzeugen ebenfalls vorhandenen Latenz, weniger störend.

* **Erhöhte Audio-Latenz bei externen Bluetooth-Audiogeräten**
  Bei der Audioausgabe über externe Bluetooth-Lautsprecher bzw. Kopfhörer (z. B. AirPods Pro) tritt eine deutlich wahrnehmbare Latenz im Vergleich zu den integrierten Lautsprechern der Vision Pro auf. Diese Verzögerung beeinträchtigt das Nutzererlebnis erheblich.

* **Keine kabelgebundene Alternative**
  visionOS bietet derzeit keine Möglichkeit, kabelgebundene Audiogeräte anzuschließen. Somit existiert keine Low-Latency-Alternative zur Bluetooth-Audioausgabe, wodurch die Latenz nicht zuverlässig reduziert oder umgangen werden kann.
