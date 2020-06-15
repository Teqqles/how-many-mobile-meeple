generate_all:   generate_fat_apk generate_split_apk generate_appbundle generate_web

generate_fat_apk:
	@echo "Building Amazon Appstore deployable..."
	flutter build apk

generate_split_apk:
	@echo "Building Github references deployable..."
	flutter build apk --split-per-abi

generate_appbundle:
	@echo "Building Play store deployable..."
	flutter build appbundle

generate_web:
	@echo "Creating Web deployment"
	flutter build web
	docker build . -t howmanymeeple/how-many-mobile-meeple

clean:
	flutter clean