import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
from sklearn.manifold import MDS

def plot_tsp_solution(n, t, d, C, routes):
    G = nx.DiGraph()
    
    # Utiliser MDS pour respecter les distances de la matrice t
    mds = MDS(n_components=2, dissimilarity='precomputed', random_state=42)
    positions_2d = mds.fit_transform(t)
    positions = {i: (positions_2d[i, 0], positions_2d[i, 1]) for i in range(n)}
    
    colors = ["red", "blue", "green"]  # Différentes couleurs pour les sous-tournées
    
    plt.figure(figsize=(8, 8))
    node_colors = ["red" if i == 0 else "skyblue" for i in G.nodes]
    
    nx.draw(G, positions, with_labels=True, node_color=node_colors, node_size=700, font_size=10, edge_color="gray")
    
    for idx, route in enumerate(routes):
        edges = [(route[i], route[i + 1]) for i in range(len(route) - 1)]
        nx.draw_networkx_edges(G, positions, edgelist=edges, edge_color=colors[idx], width=2.5)
    
    # Ajouter les étiquettes des demandes
    demand_labels = {i: f"{i}\nD={d[i]}" for i in range(n)}
    nx.draw_networkx_labels(G, positions, labels=demand_labels, font_size=8, verticalalignment='bottom')
    
    plt.title("Visualisation du TSP Robuste (Distances Respectées)")
    plt.show()

# Données
n = 8
t = np.array([
    [0, 408, 151, 535, 854, 318, 304, 301],
    [408, 0, 296, 737, 671, 713, 591, 704],
    [151, 296, 0, 497, 709, 422, 307, 418],
    [535, 737, 497, 0, 671, 449, 240, 489],
    [854, 671, 709, 671, 0, 1002, 756, 1024],
    [318, 713, 422, 449, 1002, 0, 251, 45],
    [304, 591, 307, 240, 756, 251, 0, 281],
    [301, 704, 418, 489, 1024, 45, 281, 0]
])
d = [0, 10, 9, 1, 10, 7, 1, 3]
C = 20

# Tournée optimale

routes = [[0, 2, 0], [0, 4, 1, 0], [0, 6, 3, 5, 7, 0]]
plot_tsp_solution(n, t, d, C, routes)
