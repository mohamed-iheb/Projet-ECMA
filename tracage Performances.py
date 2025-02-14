import numpy as np
import matplotlib.pyplot as plt

# Exemple de données : temps de résolution des différentes méthodes
timeS =[]
timeL =[]
timeD =[]
timeP =[]

timeS+=[0.067, 0.091, 0.02, 0.018, 0.031, 0.026, 0.045, 0.063, 0.047, 0.056, 0.096, 0.047]
timeL+=[2.018, 0.726, 0.049, 0.064, 0.101, 0.29, 0.077, 0.444, 0.187, 0.298, 0.231, 0.852]
timeD+=[2.046, 0.225, 0.023, 0.024, 0.03, 0.034, 0.031, 0.087, 0.065, 0.057, 0.14, 0.086]
timeP+=[2.542, 5.177, 0.077, 0.132, 0.069, 0.169, 0.081, 0.573, 0.226, 0.469, 0.282, 4.923]

# Trier les temps pour chaque méthode
timeS.sort()
timeD.sort()
timeL.sort()
timeP.sort()

# Nombre cumulé d'instances résolues
instances_S = np.arange(1, len(timeS) + 1)
instances_D = np.arange(1, len(timeD) + 1)
instances_L = np.arange(1, len(timeL) + 1)
instances_P = np.arange(1, len(timeP) + 1)

# Création du graphique avec plt.step() pour un affichage en marches
plt.figure(figsize=(8, 6))

plt.step(timeS, instances_S, label="Résolution du Problème Statique", color='blue', linewidth=2, where='post')
plt.step(timeD, instances_D, label="Résolution par dualisation", color='orange', linewidth=2, where='post')
plt.step(timeL, instances_L, label="Résolution par B&C", color='purple', linewidth=2, where='post')
plt.step(timeP, instances_P, label="Résolution par plans coupants", color='red', linewidth=2, where='post')

# Ajouter labels et légende
plt.xlabel("Temps (s)")
plt.ylabel("Nombre d'instances résolues")
plt.title("Diagramme de performances")
plt.legend()
plt.grid()

# Afficher le graphique
plt.show()
