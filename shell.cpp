#include <qasm.h>

void runShell(void)
{
	char *cmdline;
	string cmd,orig;
	string cmd1;
	bool done=false;
	const char *prompt="qasm: ";

	using_history();
	printf("\nWelcome to qAsm shell.\n\n");

	while(!done)
	{
		cmdline=readline(prompt);
		if (cmdline!=NULL)
		{
			cmd=cmdline;
			free(cmdline);
			cmd=trim(cmd);
			orig=cmd;
			cmd1=cmd;
			cmd=toUpper(cmd);
			if ((cmd=="QUIT") || (cmd=="EXIT"))
			{
				done=true;
			}
			else
			{
				add_history(orig.c_str());
				system(orig.c_str());
			}
			//printf("\n");
		}
	}
}