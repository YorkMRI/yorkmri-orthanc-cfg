.PHONY: TBD

local: build1 build2

ec2: build1 build3

build1:
	$(info --- Hehe ---)
	-@echo build xyz
build2:
	-@echo build abc
build3:
	-@echo build def
