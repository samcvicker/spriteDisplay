spriteDisplay.smc: spriteDisplay.asm spriteDisplay.link
	wla-65816 -vo spriteDisplay.asm spriteDisplay.obj
	wlalink -vr spriteDisplay.link spriteDisplay.smc
	git add *
	git commit -m "auto-commit from makefile"
	git push
