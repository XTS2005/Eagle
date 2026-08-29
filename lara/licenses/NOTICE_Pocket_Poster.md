# Pocket Poster and wallpaper catalog notice

Portions of the animated-wallpaper workflow, including Eagle's on-device
PosterBoard descriptor import bridge, are adapted from Pocket Poster by
leminlimez and its contributors:

https://github.com/leminlimez/Pocket-Poster

The bridge follows the `.Trash` symbolic-link import flow in these upstream
files:

- `Pocket Poster/Controllers/SymHandler.swift`
- `Pocket Poster/Controllers/PosterBoardManager.swift`

Pocket Poster is distributed under the GNU General Public License version 3.
The original source and license are available here:

https://github.com/leminlimez/Pocket-Poster/blob/main/LICENSE

Eagle modifies the flow to resolve PosterBoard's container on-device through
Lara's prepared filesystem access, verify imported descriptor contents, clean
up the temporary bridge, and roll back incomplete imports. Eagle remains
distributed under the GNU Affero General Public License version 3.

The in-app animated-wallpaper and passcode-theme catalogs use the public
manifests, previews, and downloadable theme packages maintained by SerStars and
community contributors in Nugget Wallpapers:

https://github.com/SerStars/Nugget-Wallpapers

Nugget Wallpapers is distributed under the GNU General Public License version
3. Individual wallpaper and theme credits are displayed in Eagle from the
catalog metadata supplied by their creators.
