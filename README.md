# Quilibrium node setup guide and auto-installer script
>[!WARNING]
> This guide is outdated. Please use the [new guide on Gitbook](https://iri.quest/quilibrium-node-guide).

⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠈⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠉⠀⢾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠈⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠉⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⡀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣰⡆⠀⢀⣾⣷⣤⠀⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⣠⣾⣿⡄⠀⠀⣶⡸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣸⣿⣿⣿⣷⡀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⣴⣿⣿⣿⣿⡄⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣿⡿⢁⣿⣿⣿⡀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⣼⣿⣿⣇⠻⣿⡇⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⣿⠃⢸⣿⣿⣿⣷⠀⠀⠈⢻⡙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋⠉⠀⡀⣰⣿⣿⣿⣿⠀⢻⡇⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠘⠀⢸⣿⣿⣿⣿⣦⣷⣄⠀⠁⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⢀⣴⣧⣿⣿⣿⣿⡿⠀⠈⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⣠⣶⠀⢻⣿⣿⣿⣿⣿⣿⣦⡀⢀⠀⠉⠛⠛⠿⠿⠿⠿⠛⠋⠀⢀⠀⣰⣿⣿⣿⣿⣿⣿⣿⠃⢰⣦⡀⠀⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣟⣠⡆⠀⠀⣼⣿⣿⣷⣀⠹⢿⣿⣿⣿⣿⣿⣿⣦⣿⣷⣶⣶⣶⣶⣶⣶⣶⣶⣿⣯⣾⣿⣿⣿⣿⣿⣿⡿⢁⣴⣿⣿⣷⡄⠀⢰⣦⣌⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣸⣿⣿⣿⣿⣿⣿⣦⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣾⣿⣿⣿⣿⣿⣷⡀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣩⣿⣿⣿⠿⠛⣡⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢻⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡙⠻⢿⣿⣿⣿⡁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠘⢩⣿⠟⠁⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠈⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠙⢿⣌⠃⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠛⠁⠀⣠⣿⣿⣿⣿⣿⣿⡿⠟⣿⣿⣿⣿⣿⣿⣿⡟⠀⠈⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣧⡀⠀⠙⠃⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠟⠉⠀⠒⠛⠛⠋⠁⠹⠛⣿⣿⠁⠀⠀⢻⣿⡟⣿⠀⠈⠛⠓⠓⠂⠈⠛⢿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⢰⣿⣿⣿⡿⠁⠀⣠⣾⣷⣶⣤⣴⣆⠀⣥⠈⠃⠀⠀⠀⠀⠛⢀⠇⢠⣶⣤⣴⣶⣷⣦⡀⠀⠹⣿⣿⣿⣧⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⠠⠀⢀⣀⠀⣀⡈⢉⠻⣿⡄⢹⠀⠀⠀⠀⠀⠀⠀⢸⠀⣾⡿⠋⠉⣀⠀⣀⣀⠀⠁⢹⣿⣿⣿⣇⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡿⠃⠀⢀⣤⡎⠀⣼⣿⣿⣿⣿⡇⠀⠛⣿⣄⡈⠳⠶⠇⠘⠿⠘⠀⠀⠀⠀⠀⠀⠀⠘⠸⠟⠀⠷⠆⠉⣀⣼⠛⠂⠀⣄⣿⣿⣿⣿⡄⠘⣦⡀⠀⠀⠹⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡟⠁⠀⣴⣿⠏⠀⢸⣿⡿⠛⠁⣼⣷⣶⠂⠈⠛⣿⣷⣶⣶⠄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠶⣶⣶⣾⣛⠉⠀⢶⣶⣿⡄⠙⠿⣿⣷⠀⠘⢿⣧⡀⠀⠹⣿⣿⣿⣿
⣿⣿⣿⡟⠀⢀⣾⡿⠃⠀⠀⠟⠉⠀⠀⢸⣿⣯⣁⣀⣀⡉⠉⠁⣀⠉⠉⠀⢀⡀⠀⠀⠀⠀⠀⠀⣠⠀⠉⠛⣁⡀⠉⠉⣁⣀⣀⣩⣿⣷⠀⠀⠈⠙⠇⠀⠈⢻⣿⣆⠀⠘⣿⣿⣿
⣿⣿⡿⠁⢠⣾⡿⠁⠀⠀⣀⣴⡟⠀⠀⡿⢿⣿⣿⣿⣭⣴⣶⣾⣿⣧⠀⣠⣿⣿⡀⠀⠀⠀⠀⣼⣿⣦⠀⠀⣿⣿⣶⣦⣬⣽⣿⣿⣿⢿⡇⠀⠸⣶⣄⡀⠀⠀⠹⣿⣆⠀⢹⣿⣿
⣿⣿⡇⢠⣾⡿⠁⢀⣴⣾⣿⣿⡇⠀⠀⢠⣾⣿⡿⠿⣿⣿⣿⣿⣿⡇⢀⣿⣿⣿⣷⡀⠀⠀⣾⣿⣿⣿⣦⠀⣿⣿⣿⣿⣿⣿⠿⣿⣿⣆⠁⠀⠀⣿⣿⣿⣶⣄⡀⢹⣿⣆⠈⢿⣿
⣿⣿⢀⣾⣿⢇⣴⣿⣿⣿⣿⣿⡇⠀⠀⡼⠛⠉⠀⣾⣿⣿⣿⣿⣿⡇⣼⣿⣿⣿⣿⣿⡀⣼⣿⣿⣿⣿⣿⠀⣿⣿⣿⣿⣿⣿⣆⠀⠙⢿⡆⠀⠀⣼⣿⣿⣿⣿⣷⡄⢻⣿⡆⢸⣿
⣿⡇⢸⣿⡿⠞⠛⠉⠉⠉⢸⣿⡇⠀⠀⢀⡀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣸⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣶⣿⣿⣿⣿⣿⣿⣿⠀⠀⡀⠀⠀⢀⣿⣿⡈⠉⠉⠙⠻⢾⣿⣷⠸⣿
⣿⠇⣾⠏⠁⣠⣆⠀⠀⠀⣾⣿⣷⠀⢀⣾⣧⠀⠸⣿⣿⣿⣿⢿⣿⣿⣿⣿⠛⠉⠀⠀⠀⠀⠀⠈⠙⢿⣿⣿⣿⣿⢿⣿⣿⣿⡿⠀⢠⣿⡆⠀⢸⣿⣿⡇⠀⠀⢠⣦⣀⠉⢿⡇⢿
⡿⠀⠁⣰⣿⣿⣿⡄⠀⠀⢻⣿⣿⡇⢸⣿⣿⣧⠀⠻⣿⣿⠇⢼⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⠀⣿⣿⡿⠁⢠⣿⣿⣿⢀⣾⣿⣿⠇⠀⠀⣸⣿⣿⣷⣌⠁⢸
⠇⣠⣾⣿⣿⣿⣿⣧⠀⠀⢸⣿⣿⣿⣾⣿⣿⣿⣷⡀⠙⢿⡆⠘⣿⣿⣿⣧⣤⣤⣤⠀⠀⠀⢠⣤⣤⣠⣿⣿⣿⡿⠀⣿⠟⠀⣰⣿⣿⣿⣿⣾⣿⣿⣿⠀⠀⢰⣿⣿⣿⣿⣿⣦⡈
⣴⣿⣿⣿⣿⣿⣿⣿⣇⠀⠈⣿⣿⣿⠿⢿⣿⣿⣿⣿⣦⡀⠙⠀⠻⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⡿⠁⠐⠁⣠⣾⣿⣿⣿⣿⡿⢿⣿⣿⡇⠀⢠⣾⣿⣿⣿⣿⣿⣿⣷
⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠸⣿⡏⠀⣄⡙⠻⣿⣿⣿⣿⣦⠀⠀⠙⠿⣿⣿⣿⡷⠀⠀⠀⢴⣿⣿⣿⡿⠟⠁⠀⢠⣾⣿⣿⣿⡿⠋⢁⡄⢸⣿⡟⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠸⡇⠀⣿⣿⣦⡈⠻⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⣤⣤⣶⣦⣤⡄⠀⠀⠀⠀⠀⣴⣿⣿⣿⡿⢋⣤⣾⣿⡇⢸⡟⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⣿⣿⣿⣿⣧⡈⢿⣿⣿⣧⠀⠀⠀⠀⠀⠈⠙⠛⠛⠉⠀⠀⠀⠀⠀⢰⣿⣿⡿⠋⣴⣿⣿⣿⣿⡇⠈⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⢸⣿⣿⣿⣿⣿⣄⠙⣿⣿⣆⢠⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣦⢀⣿⣿⡟⢁⣾⣿⣿⣿⣿⡿⠁⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣆⠘⢿⣿⣾⢻⡄⠀⠀⠀⠀⠀⠀⠀⠀⣾⠻⣾⣿⠏⢀⣿⣿⣿⣿⣿⣿⣷⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠈⢿⠃⠘⣿⡀⣠⠀⠀⠀⢀⠀⣼⡿⠀⣿⠏⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⣿⣷⠸⡄⠀⠀⣿⢠⣿⡇⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⣠⠀⢻⣿⣆⣧⠀⢀⣧⣿⣿⠀⢠⡀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣿⡀⠈⣿⣿⣿⠀⢸⣿⣿⡟⠀⣾⡇⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢠⣿⣷⠀⢻⣿⣿⡀⣿⣿⣿⠁⢰⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣼⣿⣿⣆⠈⣿⣿⣿⣿⣿⠏⢀⣿⣿⣿⡀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠘⡿⢻⠻⡿⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⣿⠀⠁⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠹⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡷⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿


>[!TIP]
> This guide contains all the info you need to install and manage a Quilibrium node, plus a special script to prepare your Ubuntu server and install the necessary applications.<br>The guide and the script are unofficial and have been created solely to support the project.

> Created by **LaMat** /// connect with me on [Farcaster](https://warpcast.com/~/invite-page/373160?id=67559391) or [Twitter](https://twitter.com/LaMat1111) /// &#x2661; [Donations](#-want-to-say-thank-you)



---

## Table of Contents

- [Best Server to Run a Quilibrium Node](#best-server-to-run-a-quilibrium-node)
- [Auto-installer script](#auto-installer-script-prepare-your-server-for-the-Quilibrium-node)
- [Backup Your keys.yml and config.yml Files](#backup-your-keysyml-and-configyml-files)
- [Setup the Firewall and gRPC Calls](#setup-the-grpc-calls)
- [Tools and links](#tools-and-links)
- [Useful Server Commands](#useful-server-commands)
- [Commands for token transfers](https://github.com/lamat1111/Quilibrium-Node-Auto-Installer/blob/main/tokens-cli-commands.md)
- [Migrate Node to a New Server](#migrate-node-to-a-new-server)
- [Set SSH keys](#set-ssh-keys-to-connect-to-your-server)
- [Troubleshooting](#troubleshooting)


## Best server to run a Quilibrium node
*Here some good options. This section is still under construction as I collect reviews from others. Thank you for using my referral links and supporting my work :-)*

### High quality $$$
 - **<a href="https://iri.quest/cherryservers" target="_blank">Cherryservers</a>**<br>
They officially support Quilibrium and are recommended by Cassie, the project's founder. Probably the best product and support available at the moment. In both the Quilibrium Discord and Telegram communities, there is 'Lili,' she works for them and can provide advice and assistance. Their servers sell out fast these days, so there is a chanche they will be out of stock, but you can join the waiting list.
Here are some pre-configured server options: <a href="https://www.cherryservers.com/server-customizer/cloud_vds_4?affiliate=CRXA3YWE">Cloud VDS 4</a> / <a href="https://www.cherryservers.com/server-customizer/e3_1240v3?affiliate=CRXA3YWE">E3-1240V3</a> / <a href="https://www.cherryservers.com/server-customizer/e3_1240v5?affiliate=CRXA3YWE">E3-1240V5</a> / <a href="https://www.cherryservers.com/server-customizer/e5_1620v4?affiliate=CRXA3YWE">E5-1620V4</a> / <a href="https://www.cherryservers.com/server-customizer/e5_1650v3?affiliate=CRXA3YWE">E5-1650V3</a> / <a href="https://www.cherryservers.com/server-customizer/e5_1650v4?affiliate=CRXA3YWE">E5-1650V4</a>
- **<a href="https://iri.quest/hostkey" target="_blank">Hostkey</a>** - best value for money after Cherryservers
- **<a href="https://iri.quest/latitude" target="_blank">Latitude</a>**

### Medium quality $$
- **<a href="https://iri.quest/bluevps" target="_blank">Blue VPS</a>**
- **<a href="https://iri.quest/pqhosting" target="_blank">Perfect Quality Hosting</a>**

### Low quality $
<i>Only use these VPS after Quilibrium version 1.5 to avoid issues. And read the notes below!</i><br>
- <a href="https://iri.quest/contabo" target="_blank">Contabo (any location outside of EU)</a><br>
- <a href="https://iri.quest/hostinger" target="_blank">Hostinger</a><br><br>
<details>
<summary>Important notes on low quality providers</summary>
<i>Both Contabo and Hostinger got a lot of hate from the community (and for good reasons). These cheap VPS will never perform great, but they do work. After mainnet (2.0) the node resource consumption will be much lower, and you will be able to use these cheaper services without the risk of being throttled by the provider. On the other hand... lower specs nodes will also earn fewer rewards. Your choice!</i><br><br>

<i>UPDATE: I have been testing Contabo for some time. Even locations outside of EU may give you issues. My take is that they are throttling the access to the network when in a VPS location there are too many nodes running. So you may have no issues for a while and then suddendly find out that your data flow has become very low. This is just my speculation, but if you choose to use the cheap Contabo servers... keep a close eye on them.</i>
</details>

>[!WARNING]
> **Providers to avoid**<br>
Contabo VPS (EU location) / Alpenhost / Netcup / Hetzner<br>
*These providers either don't support Quilibrium, blockchain nodes in general, or have been reported giving issues to users running nodes.*


# Auto-installer script: prepare your server for the Quilibrium node

*This script is simply packing all the necessary steps and the required applications in a one-click solution. It won't install your node (you will need to do it manually for security reasons), but it will prepare your server very quickly. You can inspect the source code [here](https://github.com/lamat1111/Quilibrium-Node-Auto-Installer/blob/main/installer). If you are not familiar with code, you can simply copy/paste the whole code in a chatbot such as ChatGPT (or any open-source alternative ;-) and ask them to explain it to you step by step.*

## Step 1
**Rent or use a server with at least 4 cores, 8 GB RAM, 250 GB SSD space, and 400 Mbit/s symmetric bandwidth.**<br>
*Outbound traffic after 1.5 should be up to 5 TB per month (raw approximation), depending on how you set the node.*<br>
You can also refer to the [Quilibrium official docs](https://quilibrium.com/docs/noderunning).<br>
Keep in mind that nodes with better specs will earn more rewards. The ratio for optimal rewards from 1.5 on theoretically will be 1:2:4 (core:ram in GB:disk in GB). Your bandwidth will also matter.<br>

VDS (Virtual Dedicated Servers) and Bare Metal (Physical dedicated Servers) are your best choiche. Using a VPS (Virtual Private Server) may give you issues as often the providers oversell the resources.<br>
That being said, using a VPS or a home machine may work just fine if you don't care about absolutely maximizing your rewards.

## Step 2
**Install the OS Ubuntu 22.04.X.**<br>
If your server has two disks, consider configuring them in "RAID 1" (typically offered by your provider). This setup mirrors one disk to the other, providing redundancy and safeguarding against data loss in case one disk fails.

## Step 3

Run the auto-installer script on your server (OS must be Ubuntu 22.04.X). I suggest you to use [Termius](https://termius.com/) to login. Be sure that you are logging in via port 22 (default with most server providers).
```
 wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer | bash
```

> [!NOTE]
> If the script fails and stops, you can try to run it again (if you understand why it stopped, then try to solve the issue first, of course). If you still receive an error, you may want to proceed manually, step by step, instead of using the auto-installer. Here is the [step by step guide](https://github.com/lamat1111/Quilibrium-Node-Auto-Installer/blob/main/installer-steps.md) you can follow.

After this step is recommended to reboot your server and login again.

## Step 4
Install your Quilibrium node 
  ```
  wget here?
  ```
Build the Quilibrium client (for transferring tokens)
  ```
  cd ~/ceremonyclient/client && GOEXPERIMENT=arenas go build -o qclient main.go
  ```

## Step 5
Run the command below. This will go to the node folder, create a persistent shell (session), start the node via the *qnode_restart* script (more info about this script below) and detach from the session again. You won't see any output after running the command, but you can move to Step 6. 
  ```
  tmux new-session -d -s quil 'export PATH=$PATH:/usr/local/go/bin && cd ~/ceremonyclient/node && ~/scripts/qnode_restart.sh'
  ```
  <blockquote>
  <details>
   <summary>Alternative: step by step commands</summary>
   You can also run these command one after the other if you prefer.
  
   ```
  cd ceremonyclient/node 
  ```
  
  ```
  tmux new-session -s quil 
  ```
  
  ```
  ~/scripts/qnode_restart.sh

  ```
To detach from tmux press CTRL+B then D. Now you can safely logout from your server and the node will keep running in its persistent shell.<br>
To reattach to the tmux session and see your node log, just use `tmux a -t quil`. You can recognize when you are inside your tmux session because there will be a green bar at the bottom of the screen.<br>
To stop the node, from inside tmux click CTRL+C <br>
To restart the node, from inside tmux run <code>./poor_mans_cd.sh</code>
</details>
</blockquote>

*The qnode_restart.sh is a script used to run the node. It will restart it automatically if it gets killed.*


>[!NOTE]
>If you ever reboot your server, you will need to go through this step 6 again to start the node from scratch.

## Step 6
**You are done!** Now you can safely logout from your server and the node will keep running in its persistent shell.
</br><br>
If you want to see you node log you can reattach to the tmux session with <code>tmux a -t quil</code><br>
Once you are in the tmux session a green bar will appear at the bottom of the screen, to detach from tmux press CTRL+B then D.<br>
It will usually takes 10 minutes before you will begin to see new log entries in the node log. And it will take  up to 30 minutes before your private keys will be created correctly, so that you can backup them.<br><br>

> [!NOTE]
> If you inspect the node log you will usually see "0 frames" for up to 72 hours before the node is fully synced with the network. After a while you will see the "master_frame_head" value increase, while the "current_head_frame" stays to 0. This is normal until your "master_frame_head" reaches the latest frame in the network. If you suspect that your node is not connecting to the network check the server bandwidth with <code>speedtest-cli</code> and check the [Troubleshooting](#troubleshooting) section wheer it says "frame 0".


## Step 7
Let you node run for at least 30 minutes, then check if you keys.yml file has been completely generated. Run the command:
  ```
wc -c /root/ceremonyclient/node/.config/keys.yml
  ```
The response should be <code>1252 /root/ceremonyclient/node/.config/keys.yml</code>. <br>If the number is lower, you need to keep the node running a bit more. You can also [check here](#backup-your-keysyml-and-configyml-files) to see how the correct file should look like.

When your keys.yml has been genearted, proceed to [backup your your keys.yml and config.yml files](#backup-your-keysyml-and-configyml-files), and [setup your gRPC calls](#setup-the-grpc-calls)

## Step 8
This is optional, but recommended! Setup SSH keys to connect to your server and disable the password connection. Here is a [guide to do this](#set-ssh-keys-to-connect-to-your-server)<br>
To enhance even more your server security, you may install and setup *Fail2ban*, here is [a guide](https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-20-04).

### Check node info
After you node has been running for at least 30 minutes, run this command from your root folder to check the node info (Node version, Peer ID, Quil balance).<br>
For this to work you need to [setup the gRPC calls](#setup-the-grpc-calls) first.<br> If you have enabled the gRPC calls but you still get an error, it usually just means that your node needs to run some more in order to correctly connect to the newtork. Retry later.
  ```
cd ~/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -node-info
  ```
*If the above command does not work, or you have not set the gRPC calls, there are alternative commands to check your PeerID and node version, just look in [Useful Server Commands](#useful-server-commands)*

### Check your QUIL balance and address (after 2.0)
  ```
cd ~/ceremonyclient/client && ./qclient token balance
  ```
> [!NOTE]
> If you get a "No such file or directory" error, run <code>cd ceremonyclient/client && go build -o qclient</code> to try and rebuild the client.<br>
> All the commands to transfer QUIL tokens are [here](https://github.com/lamat1111/Quilibrium-Node-Auto-Installer/blob/main/tokens-cli-commands.md).

## Backup your keys.yml and config.yml files
After 30 minutes that then node has been running, it should have generated your keys and config files correctly.
Use [WinSCP](https://winscp.net/eng/index.php) or [Termius SFTP feature](https://support.termius.com/hc/en-us/articles/4402367330201-SFTP) to navigate to the `root/ceremonyclient/node/.config`  folder. You may have to enable visibility for hidden files in WinSCP if you don't see the .config folder. Select Options, Preferences from the main menu, then the Panels tab, and check the option to Show hidden files (Ctrl+Alt+H).

Download locally your `keys.yml` and `config.yml` files. Keep them safe and do not share them with anyone!
Is a good idea to put them in an encrypted folder using a free tool such as [Encrypto](https://macpaw.com/encrypto)

If you need to migrate the node elsewhere, after installing the node from scratch you just need to put these 2 files in the `root/ceremonyclient/node/.config`  folder (changing the ones automatically created by the node). Here is a [quick way to do this](#migrate-node-to-a-new-server).

<details><summary>What does a correct "keys.yml" file look like?</summary>
 
 ```
"":
  id: ""
  type: 0
  privateKey: ""
  publicKey: ""
default-proving-key:
  id: default-proving-key
  type: 0
  privateKey: ////long-key-here///
  publicKey: ////long-key-here///
q-ratchet-idk:
  id: q-ratchet-idk
  type: 1
  privateKey: ////long-key-here///
  publicKey: ////long-key-here///
q-ratchet-spk:
  id: q-ratchet-spk
  type: 1
  privateKey: 
 ```
</details>

<details><summary>What does a correct "config.yml" file look like?</summary>
  
 ```
key:
  keyManagerType: file
  keyManagerFile:
    path: .config/keys.yml
    createIfMissing: false
    encryptionKey: ////long-key-here///
p2p:
  d: 0
  dLo: 0
  dHi: 0
  dScore: 0
  dOut: 0
  historyLength: 0
  historyGossip: 0
  dLazy: 0
  gossipFactor: 0
  gossipRetransmission: 0
  heartbeatInitialDelay: 0s
  heartbeatInterval: 0s
  fanoutTTL: 0s
  prunePeers: 0
  pruneBackoff: 0s
  unsubscribeBackoff: 0s
  connectors: 0
  maxPendingConnections: 0
  connectionTimeout: 0s
  directConnectTicks: 0
  directConnectInitialDelay: 0s
  opportunisticGraftTicks: 0
  opportunisticGraftPeers: 0
  graftFloodThreshold: 0s
  maxIHaveLength: 0
  maxIHaveMessages: 0
  iWantFollowupTime: 0s
  bootstrapPeers:
  ////list-of-bootstrap-peers-here///
  listenMultiaddr: /ip4/0.0.0.0/udp/8336/quic
  peerPrivKey: ////long-key-here///
  traceLogFile: ""
  minPeers: 0
engine:
  provingKeyId: default-proving-key
  filter: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
  genesisSeed: ////very-long-seed-here///
  maxFrames: -1
  pendingCommitWorkers: 4
  minimumPeersRequired: 0
  statsMultiaddr: ""
  difficulty: 0
db:
  path: .config/store
listenGrpcMultiaddr: ""
listenRESTMultiaddr: ""
logFile: ""
 ```
</details>

## Setup the gRPC calls
*This step is not required for the node to work. Even if you receive errors, your node should not be affected and keep running normally.*

After your node has been running for 30 minutes, run the below script to setup the gRPC calls.
```bash
wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer-gRPC-calls | bash
```
<details>
 <summary>How to enable gRPC calls manually</summary>
1. Open the file root/ceremonyclient/node/.config/config.yml on your local pc using WinSCP<br>
 
2. Find <code>listenGrpcMultiaddr: “”</code> (end of the file) and replace it with  <code>listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337</code><br>

3. Find <code>engine:  </code>(about the middle of the file) and paste<code>  statsMultiaddr: "dns/stats.quilibrium.com/tcp/443"</code> right below it, with two empty spaces before the line<br>

4. Save the file
</details>

## Install extra tools

<details>
<summary>vnstat - monitor bandwidth and data flow</summary>
 
 ```bash
sudo apt update && sudo apt install vnstat
 ```
To check the current bandwidth usage use <code>vnstat</code>. <br>
To check hourly stats e use <code>vnstat -h</code>. <br>Daily: <code>vnstat -d</code>. Monthly: <code>vnstat -m</code>. Top 10 traffic days: <code>vnstat -t</code>. 
</details>

<details>
<summary>speedtest - monitor bandwidth speed</summary>
 
 ```bash
sudo apt-get install curl
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
 ```
 </details>

 <details>
<summary>htop - monitor all processes and resources' consumption</summary>
 
 ```bash
sudo apt update && sudo apt install htop
 ```
To use it just type <code>htop</code>
 </details>

------
------
------

# Tools and links
 - To manage your nodes use [Termius](https://termius.com/), the coolest SSH client and terminal around :) 
 - To track your server uptime and  resources usage use [Hetrixtools.com](https://hetrix.tools/u-862828), you can track up to 15 servers for free and the setup is very easy
 - If you need help with your node come to the [Quilibrium Community Discord](https://discord.gg/quilibrium) or the [Quilibrium Telegram group](https://t.me/quilibrium)

<details>
<summary>Community links</summary>
- <a href="https://discord.gg/quilibrium">Discord</a><br>
- <a href="https://docs.quilibrium.space/">Documentation</a><br>
- <a href="https://t.me/quilibrium">Telegram</a><br>
- <a href="https://twitter.com/Quilibrium_xyz">Twitter</a>
</details>

<details>
<summary>Official links</summary>
- <a href="https://quilibrium.com/">Website</a><br>
- <a href="https://warpcast.com/~/channel/quilibrium">Warpcast</a><br>
- <a href="https://quilibrium.com/quilibrium.pdf">Whitepaper</a><br>
- <a href="https://github.com/quilibriumnetwork/">Github</a><br>
<br>
- <a href="https://opensea.io/collection/long-live-the-internet">NFT</a><br>
- <a href="https://paragraph.xyz/@quilibrium.com">Blog</a><br>
- <a href="https://cassieheart.substack.com/">Cassies's (lead dev) blog</a>
</details>

<details>
<summary>Buy token (wQUIL ERC-20)</summary>
- <a href="0x8143182a775c54578c8b7b3ef77982498866945d">Contract</a><br>
- <a href="https://discord.gg/quilibrium">OTC (Community Discord)</a><br>
- <a href="https://app.uniswap.org/swap?inputCurrency=ETH&outputCurrency=0x8143182a775c54578c8b7b3ef77982498866945d">Uniswap</a><br>
- <a href="https://www.dextools.io/app/en/ether/pair-explorer/0x43e7ade137b86798654d8e78c36d5a556a647224">Dextools</a>
</details>

<details>
<summary>Videos</summary>
- <a href="https://www.youtube.com/watch?v=GeuZsX6dC08">The "Alternative" Thesis of Consumer Crypto (backstory)</a><br>
- <a href="https://www.youtube.com/watch?v=_mO07gDTX7Q">Quilibrium Overview: How does it tick? (technical)</a><br>
- <a href="https://www.youtube.com/watch?v=Ye677-FkgXE">Quilibrium Q&A, Roadmap, High Level Explainer (technical)</a>
</details>
=======

<details>
<summary>Official links</summary>
- <a href="https://quilibrium.com/">Website</a><br>
- <a href="https://warpcast.com/~/channel/quilibrium">Warpcast</a><br>
- <a href="https://quilibrium.com/quilibrium.pdf">Whitepaper</a><br>
- <a href="https://github.com/quilibriumnetwork/">Github</a><br>
<br>
- <a href="https://opensea.io/collection/long-live-the-internet">NFT</a><br>
- <a href="https://paragraph.xyz/@quilibrium.com">Blog</a><br>
- <a href="https://cassieheart.substack.com/">Cassies's (lead dev) blog</a>
</details>

<details>
<summary>Buy token (wQUIL ERC-20)</summary>
- <a href="0x8143182a775c54578c8b7b3ef77982498866945d">Contract</a><br>
- <a href="https://discord.gg/quilibrium">OTC (Community Discord)</a><br>
- <a href="https://app.uniswap.org/swap?inputCurrency=ETH&outputCurrency=0x8143182a775c54578c8b7b3ef77982498866945d">Uniswap</a><br>
- <a href="https://www.dextools.io/app/en/ether/pair-explorer/0x43e7ade137b86798654d8e78c36d5a556a647224">Dextools</a>
</details>

<details>
<summary>Videos</summary>
- <a href="https://www.youtube.com/watch?v=GeuZsX6dC08">The "Alternative" Thesis of Consumer Crypto (backstory)</a><br>
- <a href="https://www.youtube.com/watch?v=_mO07gDTX7Q">Quilibrium Overview: How does it tick? (technical)</a><br>
- <a href="https://www.youtube.com/watch?v=Ye677-FkgXE">Quilibrium Q&A, Roadmap, High Level Explainer (technical)</a>
</details>

# Useful server commands

>[!NOTE]
> If you are looking for commands to transfer QUIL tokens, please [look here](https://github.com/lamat1111/Quilibrium-Node-Auto-Installer/blob/main/tokens-cli-commands.md)

<details>
<summary>Check node info</summary>
After you node has been running for at least 30 minutes, run this command from your root folder to check the node info (Node version, Peer ID, Quil balance).<br>
For this to work you need to [setup the gRPC calls](https://github.com/lamat1111/quilibrium-node-auto-installer/blob/main/README.md#setup-the-grpc-calls) first.<br>
To go to the root folder just type cd .
 
  ```
cd ~/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -node-info
  ```
</details>
<br>
<details>
<summary>Check node version</summary>
If the "Check node info" command above do not work, you can check the node version by running:
 
  ```
cat ~/ceremonyclient/node/config/version.go | grep -A 1 'func GetVersion() \[\]byte {' | grep -Eo '0x[0-9a-fA-F]+' | xargs printf '%d.%d.%d'
  ```
</details>
<details>
<summary>Check node peer ID</summary>
If the "Check node info" command above do not work, you can check the node peer ID by running:
 
  ```
cd ~/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -peer-id
  ```
</details>
<details>
<summary>Console</summary>
Similar to "Node info", this will show basic info about your node.
 
  ```
cd ~/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... --db-console
  ```
</details>
<details>
<summary>Attach to existing tmux session</summary>
 
```bash
tmux a -t quil
```
To detach from tmux press CTRL+B then release both keys and press D
</details>
<details>
<summary>Create tmux session + run node + detach from session: 1 step command</summary>
This is useful to quickly run then node in a session AFTER you have rebooted your server. Only RUN this after a reboot and if you have no tmux session already active.<br>
The last part <code>~/scripts/qnode_restart.sh</code> will only work if you have run the autoinstaller in this guide. Otherwise you have to use <code>GOEXPERIMENT=arenas go run ./...</code>
 
```bash
tmux new-session -d -s quil 'export PATH=$PATH:/usr/local/go/bin && cd ~/ceremonyclient/node && ~/scripts/qnode_restart.sh'
```
 </details>
 <details>
<summary>Create cronjob to run the node automatically after a reboot</summary>
DO NOT USE AFTER 1.4.17
You only have to run this command once. This will setup a cronjob that will create your tmux session and run the node automatically after every reboot of your server.
Shoutout to Peter Jameson (Quilibrium Discord community creator) for the script.<br>
The last part <code>~/scripts/qnode_restart.sh</code> will only work if you have run the autoinstaller in this guide. Otherwise you have to use <code>GOEXPERIMENT=arenas go run ./...</code>
 
```bash
echo "@reboot sleep 10 && tmux new-session -d -s quil 'export PATH=\$PATH:/usr/local/go/bin && cd ~/ceremonyclient/node && ~/scripts/qnode_restart.sh'" | crontab -
```

If you need to delete the crontab:<br>
Open the crontab file for editing with <code>crontab -e</code><br>
Locate the line corresponding to the cron job you want to delete and delete it. Press CTRL+X, then Y to save, then ENTER
 </details>
<details>
<summary>Kill node process</summary>
Use this in case you need to stop the node and kill the process
 
```bash
pkill node && pkill -f "go run ./..."
```
</details>
<details>
<summary>Empty "store" folder</summary>
CAREFUL: this will empty your "store" folder, only use it if you know what you are doing.
Sometimes when you receive errors that you cannot debug, you can solve by killing the node process, emptying the store folder and starting the node again from scratch.
 
```bash
sudo rm -r ~/ceremonyclient/node/.config/store
```
</details>

<details>
<summary>Backup keys.yml and config.yml to a root/backup folder</summary>
This may be useful if you have to cleanup your ceremonyclient folder and don't want to download locally your config.yml and keys.yml. You can just backup them remotely on a root/backup folder and copy them again in the node folder later on.

Copy the files from your node folder to the root/backup folder
```bash
mkdir -p /root/backup && cp /root/ceremonyclient/node/.config/config.yml /root/backup && cp /root/ceremonyclient/node/.config/keys.yml /root/backup
```

Copy the files back from root/backup to your node folder (a copy will also remain in the root/backup folder)
```bash
cp /root/backup/{config.yml,keys.yml} /root/ceremonyclient/node/.config/
```
</details>

<details>
<summary>Check total nodes connected to the network</summary>
Install grpcURL
 
```bash
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

Run
 ```bash
/root/go/bin/grpcurl -plaintext -max-msg-sz 5000000 localhost:8337 quilibrium.node.node.pb.NodeService.GetPeerInfo | grep peerId | wc -l
```
</details>

# Migrate node to a new server
> [!NOTE]
> This guide will only work if you use username and password to access yuor target server (which is not the best for security). If you use an SSH key, you will need to follow a more advanced method. Or you can simply setup an SSH key AFTER you have migrated the files to the target server.
1. Use the auto-installer script in this guide to install the node on the new server and let it run for 10 minutes (or for the time necessary for the root/ceremonyclient/node/.config folder to appear) then stop it with CTRL+C . *This step is clearly optional if you have already installed the node*. 
2. Grab your new server IP and password.
3. Login to the old server and run this command.
*Change <NEW_SERVER_IP> with your new server IP and enter the new server password when requested.*

```bash
scp -f ~/ceremonyclient/node/.config/keys.yml ~/ceremonyclient/node/.config/config.yml root@<NEW_SERVER_IP>:/root/ceremonyclient/node/.config/
```
<blockquote>
ATTENTION: The command will ovewrite any existing keys.yml and config.yml files in the target server with no confirmation.

The command will move your keys.yml and config.yml to new server. For this to work the node must already be installed in the new server and the .config folder be generated.
</blockquote>

### Manual method
Alternatively you can migrate the files manually. If you already have a local backup of the config.yml and keys.yml files, you just need to upload them to your new server in the folder `root/ceremonyclient/node/.config` . You can use use [WinSCP](https://winscp.net/eng/index.php) to do this.

# Set SSH keys to connect to your server
> [!NOTE]
> Usually, when you rent a server, you are given a username and password to connect to it. However, this poses a security risk as hackers can attempt to guess your password using brute force attacks. To mitigate this risk, you can disable password access to your server and use SSH keys instead.

Here is a [comprehensive guide](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-22-04) on how to set up SSH keys on your server.

**Alternatively, you can use Termius, which offers a simpler method as outlined below:**

1. Install [Termius](https://termius.com/) and follow [this guide](https://support.termius.com/hc/en-us/articles/4401872025113-Keychain) to generate an SSH key. Remember to securely store your key, either in an encrypted folder on your computer or on an encrypted USB drive.
2. Through Termius, you can easily export the SSH key to your host and create an identity as explained in the guide.
3. Test that you can successfully connect to the server using this SSH key.
4. If you have multiple nodes or servers, you can use the same SSH key for all of them.
5. Once logged into your server, run `sudo nano /etc/ssh/sshd_config`.
6. Scroll down using the down arrow until you locate the line `# PasswordAuthentication yes`. Uncomment the line (remove #) and set it to `no`, like so: `PasswordAuthentication no`.
7. To save the changes, press CTRL+X, then Y, then ENTER.
8. Restart your SSH service by running `sudo systemctl restart ssh`.

Now, you should only be able to access the server via SSH key, and password-based access will no longer work.

# Troubleshooting
<details>
<summary>Panic: resource temporarily unavailable</summary>
This error means you have an already running instance of the node. Follow the step below to kill all nodes and restart just one instance.
</details>
<details>
<summary>How to kill and restart the node</summary>
Sometimes you may need to kill and restart the node. For instance if you made the mistake of starting 2 separate instances of the node.<br>
You may also verify this by running the command <code>ps -ef</code> . It will list all your running processes, look for ".../exe/node". There should be only one.

<br><br>
Go to your root folder

```bash
cd root
```
Kill all the node processes
```bash
pkill node && pkill -f "go run ./..."
```
Go into your tmux session and start again the node. <br><code>~/scripts/qnode_restart.sh</code> will only work if you have run the autoinstaller in this guide. Otherwise you have to use <code>GOEXPERIMENT=arenas go run ./...</code>
  ```
  tmux a -t quil
  ```
  
  ```
  ~/scripts/qnode_restart.sh
  ```
To detach from tmux press CTRL+B then D.
</details>

<details>
<summary>Errors on servers that already hosted a node</summary>
If you've already attempted to install a node on your server and then ran the auto-install script, you may encounter errors. Execute these commands sequentially, and they should typically suffice for initiating a new installation.
 
```bash
sudo swapoff /swap/swapfile 2>/dev/null; sudo sed -i '/\/swap\/swapfile/d' /etc/fstab; sudo rm /swap/swapfile 2>/dev/null; sudo rmdir /swap 2>/dev/null || sudo rm -rf /swap
```
```bash
sudo rm -rf /usr/local/go && sudo rm -rf /root/ceremonyclient
```
</details>
<details>
<summary>Command GO not found - add variables to your .bashrc</summary>
If you see the error *Command GO not found*, then try to run this command. Thsi will add some variables to your .bashrc file

```bash
echo -e "\nexport PATH=\$PATH:/usr/local/go/bin:\$HOME/go\nexport GOEXPERIMENT=arenas" >> ~/.bashrc
```
<br>
Alternatively, you can temporarily add these variables using the command below. Please note that these changes will not persist after rebooting the server:
 
```bash
export PATH=$PATH:/usr/local/go/bin:$HOME/go
export GOEXPERIMENT=arenas
```
<br><br>
If you receive the error while trying to run your *poor_mans_cd* script in your tmux session, press CTRL+C to stop the process, then run 
```bash
export PATH=$PATH:/usr/local/go/bin:$HOME/go
export GOEXPERIMENT=arenas
```
and finally try to run again the script 
```bash
./poor_mans_cd.sh
```
---
The issue could also be caused by these variables having been added more than once. Open your <code>root/.bashrc</code> file with Termius SFTP or WinSCP and scroll down until you see
```bash
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export GOEXPERIMENT=arenas
```
If there are duplicates, delete them and save. If something is missing, you can add manually the missing lines and save.

</details>

<details>
<summary>Remove gRPC calls settings from config.yml</summary>
If you want to remove the gRPC calls setting from your config.yml file here is what you have to do:<br>
1. Open the file root/ceremonyclient/node/.config/config.yml on your local pc using WinSCP<br>
2. Find <code>listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337</code> and replace it with <code>listenGrpcMultiaddr: “”</code><br>
3. Find <code>statsMultiaddr: "dns/stats.quilibrium.com/tcp/443"</code> and remove the line completely<br>
now your config.yml should be as it was generated by the node itself
</details>
<details>
<summary>How to debug your config.yml</summary>
A simple way to debug your config.yml file if you are not a dev is to create a node from scratch an download locally the config.yml file.
Then download the config.yml of your working node, the one you have edited either via a script or manually.

At this point use a tool such as Diffinity - https://truehumandesign.se/s_diffinity.php, to compare the 2 files.

The encryption keys will be different of course, and you may have some more lines in the "bootstrapPeers" section of one of the files, but you should easily see the lines you have added or if there is any typing error in the file you edited.
</details>
<details>
<summary>Frame number: 0</summary>
If you see *Frame number:0* in your node log for a long time, one way to debug is to check if access to the network is healthy and that port 8336 is accessible remotely.<br>
1. From your local PC or a system other than the node:<br>
2. Make sure you have netcat installed: <code>sudo apt install netcat</code><br>
3. Confirm reachability of bootstrap: <code>nc -vzu YOUR_SERVER_IP 8336</code><br>
<i>Replace YOUR_SERVER_IP with your node's IP*</i>
</details>
<details>
<summary>Panic: get parent data clock frame: item not found</summary>
If you imported an external "store" folder to kickstart your node syncronization, you may see this error, while the node keeps crashing.<br>
Stop the node, delete the "SELF_TEST" file from your ".config" folder, and restart the node. If this doesn't solve, try to  import in the ".config" folder the "REPAIR" file form another working node, and delete the existing one.<br>
Give the node 10-15 minutes to see if everything works correctly.
</details>

# Changes after 1.4.17
>[!NOTE]
>If you have used this autoinstaller before 14.05.2025, you need to make some small changes right before or after 1.4.18 is released. Just login in your server and follow the steps below.

kill your tmux session
```
tmux kill-session -t quil
```

create a new tmux session
```
cd ceremonyclient/node && tmux new-session -s quil
```

when inside the tmux session (green bar at the bottom of the screen) run the below command to start the node again without the poor_mans_cd script
```
GOEXPERIMENT=arenas go run ./...
```

detatch from the tmux session by pressing CTRL+B and then D

Now your node is running again, but you will have to perform manually any future update. Probably a new autoupdate official script will be provided and this autoinstaller guide will be updated accordingly. Stay tuned!

---

### &#x2661; Want to say thank you?

Apart from using my referral links in the guide for Cherryservers and other providers, you can buy me a cup of something with a small donation.
<details><summary>Donate QUIL</summary>
 
```
coming soon...
```
</details>
<details><summary>Donate ERC20</summary>
 
```
0x0fd383A1cfbcf4d1F493Dd71b798ebca89e8a013
```
Any token that lives on the Ethereum network or Layer2
</details>

