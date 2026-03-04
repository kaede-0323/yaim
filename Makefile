YAIM = result/yaim
SRC = src/main.nim
VERSION = 1.0.0

.PHONY: all debug release clean-debug clean-release

all: debug release

debug:
	nim cpp -o:$(YAIM)-$(VERSION)-DEBUG $(SRC)

clean-debug:
	rm -f $(YAIM)-$(VERSION)-DEBUG

release:
	nim cpp -o:$(YAIM)-$(VERSION) -d:release $(SRC)

clean-release:
	rm -f $(YAIM)-$(VERSION)
