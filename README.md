dataset-builds
==============

Some help script to build smartos datasets.

After checking everything is ok:
# zfs send zones/77162147-ff0d-4817-8db0-6590f19953ac@8c9999d5-7e7c-47d4-80b0-e7b06b4bbe43 | bzip2 > /zones/ISOS/owncloud-13.1.0.zfs.bz2
# Build manifest:
	digest -a sha1
	echo killfill | md5 -> creator_uuid
	Manually build the manifest (ej: http://datasets.at/datasets/77162147-ff0d-4817-8db0-6590f19953ac)
# Upload with httpie:
http -f -a USER:PASS PUT http://datasets.at/datasets/77162147-ff0d-4817-8db0-6590f19953ac manifest@owncloud-13.1.0.dsmanifest owncloud-13.1.0.zfs.bz2@owncloud-13.1.0.zfs.bz2
