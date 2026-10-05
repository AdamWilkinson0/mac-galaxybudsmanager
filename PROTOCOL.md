# Galaxy Buds2 Pro control protocol (notes)

Everything here is worked out from my own buds and my own captures.

## 1. Services (SDP)

Ran `budsprobe` against the paired Buds2 Pro (fw unknown yet). 15 SDP records came back.
The standard ones are audio stuff (A2DP sink/source `110b`/`110e`/`110f`, AVRCP `110c`, HFP `111e`, PnP `1200`).

The rest are vendor services with 128-bit uuids, each on its own RFCOMM channel:

| name          | rfcomm ch | uuid                                 |
|---------------|-----------|--------------------------------------|
| FACTORY       | 20        | 00001101-0000-1000-8000-00805f9b34fb (plain SPP) |
| BTIS          | 21        | e7ab2241-ca64-4a69-ac02-05f5c6fe2d62 |
| DEVICEID      | 22        | d908aab5-7a90-4cbe-8641-86a553db0146 |
| UUID128       | 26        | b4a9d6a0-b2e3-4e40-976d-a69f167ea895 |
| GEARMANAGER   | 27        | 2e73a4ad-332d-41fc-90e2-16bef06523f2 |
| SAMSUNGDEVICE | 28        | a23d00bc-217c-123b-9c00-fc44577136ee |
| SPPSERVICE4   | 29        | f8620674-a1ed-41ab-a8b9-de9ad655729d |
| MULTIPOINT    | 30        | e74beac1-ab40-423f-b746-fb9869a982dd |

**Open question:** which of these the phone app uses for settings. Plan is to look at which
RFCOMM channel the phone opens in the HCI snoop log, and to listen passively on each one from the Mac.
Channel numbers could change with firmware, so the app should look the service up by uuid, not by number.

Evidence: `budsprobe` output, 2026-10-05.
