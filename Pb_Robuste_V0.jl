using JuMP
using CPLEX

# Charger les données depuis le fichier
include("data/instance_n5.txt")

n = 5
t = [
    0 260 864 263 374;
    260 0 796 59 114;
    864 796 0 855 797;
    263 59 855 0 130;
    374 114 797 130 0
]
T = 6
th = [6, 1, 2, 8, 1]
d = [0, 6, 2, 5, 3]
C = 6

# Ensemble des arcs
nodes = 1:n
A = [(i, j) for i in nodes, j in nodes if i != j]

# Modèle maître
model = Model(CPLEX.Optimizer)

@variable(model, x[i in nodes, j in nodes], Bin)  # Variable binaire pour les arcs
@variable(model, u[i in nodes] >= 0)  # Quantité livrée à chaque nœud
@variable(model, z)  # Variable de robustesse

# Fonction objectif (minimisation des coûts de tournée)
@objective(model, Min, z)

# Contraintes
for i in nodes
    if i != 1
        @constraint(model, sum(x[j, i] for j in nodes if j != i) == 1)  # Un véhicule arrive
        @constraint(model, sum(x[i, j] for j in nodes if j != i) == 1)  # Un véhicule part
    end
end
@constraint(model, sum(x[1, j] for j in nodes if j != 1) == sum(x[j, 1] for j in nodes if j != 1))  # Retour au dépôt

# Contraintes de capacité
for i in nodes
    if i != 1
        @constraint(model, u[i] <= C - d[i])
    end
end

for i in 2:n
    for j in 2:n
        if j != 1
            @constraint(model, u[j] - u[i] >= d[i] - C * (1 - x[i, j]))
        end
    end
end

for j in nodes
    if j != 1
        @constraint(model, u[j] <= C * (1 - x[1, j]))
    end
end

# Contraintes de robustesse pour chaque arc (i, j)
for i in nodes, j in nodes
    if i != j
        @constraint(model, z >= t[i, j] * x[i, j])  # + th[i] * x[i, j]
    end
end

# Définir le callback pour les plans coupants
function cutting_plane_callback(cb_data)
    # Obtenez les valeurs actuelles des variables
    x_val = callback_value.(cb_data, x)
    z_val = callback_value(cb_data, z)

    # Ajoutez une coupe si nécessaire
    for (i, j) in A
        t_robust = t[i, j] + th[i] + th[j]
        if z_val < t_robust * x_val[i, j]
            # Ajout de la coupe via l'interface de CPLEX
            cb_data.add_lazy_constraint(z >= t_robust * x[i, j])
        end
    end
end

# Configurer le callback
MOI.set(model, MOI.LazyConstraintCallback(), cutting_plane_callback)

# Résolution
optimize!(model)

# Vérifiez si une solution faisable a été trouvée
if termination_status(model) in [MOI.OPTIMAL, MOI.FEASIBLE]
    println("Objective value (coût total) : ", objective_value(model))
    println("x values (arcs choisis) :")
    for i in nodes, j in nodes
        if value(x[i, j]) > 0.5
            println("Arc ($i -> $j)")
        end
    end
    println("u values (quantité livrée) : ", value.(u))
    println("z value (valeur robuste) : ", value(z))
else
    println("Aucune solution faisable trouvée. Statut : ", termination_status(model))
end
