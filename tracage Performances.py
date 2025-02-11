import numpy as np
import matplotlib.pyplot as plt

# Exemple de données : temps de résolution des différentes méthodes
timeS =[0.021, 0.02, 0.038, 0.045, 0.049, 0.023, 0.059, 0.059, 0.042, 0.072]
timeL =[1.096, 0.059, 0.187, 0.193, 0.663, 0.209, 0.301, 0.227, 0.681, 0.532]
timeD =[0.869, 0.029, 0.111, 0.125, 0.099, 0.033, 0.074, 0.063, 0.077, 0.193]


# Trier les temps pour chaque méthode
timeS.sort()
timeD.sort()
timeL.sort()

# Nombre cumulé d'instances résolues
instances_S = np.arange(1, len(timeS) + 1)
instances_D = np.arange(1, len(timeD) + 1)
instances_L = np.arange(1, len(timeL) + 1)

# Création du graphique avec plt.step() pour un affichage en marches
plt.figure(figsize=(8, 6))

plt.step(timeS, instances_S, label="Résolution du Problème Statique", color='blue', linewidth=2, where='post')
plt.step(timeD, instances_D, label="Résolution par dualisation", color='orange', linewidth=2, where='post')
plt.step(timeL, instances_L, label="Résolution par plans coupants", color='purple', linewidth=2, where='post')

# Ajouter labels et légende
plt.xlabel("Temps (s)")
plt.ylabel("Nombre d'instances résolues")
plt.title("Diagramme de performances")
plt.legend()
plt.grid()

# Afficher le graphique
plt.show()
