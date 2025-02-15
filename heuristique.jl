# Fonction pour calculer t'
function calculer_t_prime(t, th, T)
    n = size(t, 1)
    delta_1 = T / n^2
    delta_2 = T^2 / n^2
    
    t_prime = float.(t) 

    for i in 1:n
        for j in 1:n
            if i != j
                t_prime[i, j] += delta_1 * (th[i] + th[j]) + delta_2 * (th[i] * th[j])
            end
        end
    end
    return t_prime
end

# Fonction de résolution heuristique
function heuristique(n, d, t, C, th, T)
    # Calcul de t'
    t_prime = calculer_t_prime(t, th, T)

    # Initialisation
    x = zeros(Int, n, n)
    clients_restants = Set(2:n)
    coût_total = 0

    while !isempty(clients_restants)
        charge = 0
        position_actuelle = 1

        while !isempty(clients_restants)
            # Trouver les clients admissibles
            candidats = [i for i in clients_restants if charge + d[i] ≤ C]

            if isempty(candidats)
                break  # Plus de clients possibles -> Retour à l'entrepôt
            else
                # Sélection du client (proximité vs ratio demande/distance)
                client_proche = argmin(i -> t_prime[position_actuelle, i], candidats)
                client_ratio = argmin(i ->  1/ d[i] , candidats) #t_prime[position_actuelle, i] *

                
                prochain = client_ratio # on choisie une des méthodes de recherche heuristique
                

                # Mise à jour des décisions et coûts
                x[position_actuelle, prochain] = 1
                coût_total += t_prime[position_actuelle, prochain]
                charge += d[prochain]
                position_actuelle = prochain
                delete!(clients_restants, prochain)
            end
        end

        # Retour à l'entrepôt
        x[position_actuelle, 1] = 1
        coût_total += t_prime[position_actuelle, 1]
    end

    return coût_total
end

# Données fournies
n = 5  
t = [
    0 260 864 263 374;
    260 0 796 59 114;
    864 796 0 855 797;
    263 59 855 0 130;
    374 114 797 130 0
]
th = [6, 1, 2, 8, 1]
T = 6
d = [0, 6, 2, 5, 3]  
C = 12  

# Résolution
valeur_objective = heuristique(n, d, t, C, th, T)
println("Valeur objective pour t' : ", valeur_objective)
