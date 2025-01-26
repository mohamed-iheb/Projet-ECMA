using JuMP
using CPLEX
using GLPK  # Pour résoudre le sous-problème comme un LP

# Données du problème
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

# Modèle principal
model = Model(CPLEX.Optimizer)

@variable(model, x[i in nodes, j in nodes], Bin)  # Variable binaire pour les arcs
@variable(model, u[i in nodes] >= 0)  # Quantité livrée à chaque nœud
@variable(model, z)  # Variable de robustesse

# Fonction objectif
@objective(model, Min, z)

# Contraintes de tournée
for i in nodes
    if i != 1
        @constraint(model, sum(x[j, i] for j in nodes if j != i) == 1)
        @constraint(model, sum(x[i, j] for j in nodes if j != i) == 1)
    end
end
@constraint(model, sum(x[1, j] for j in nodes if j != 1) == sum(x[j, 1] for j in nodes if j != 1))

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

# Callback pour résoudre le sous-problème
function cutting_plane_callback(cb_data)
    # Obtenez les valeurs actuelles de x
    x_val = callback_value.(cb_data, x)
    z_val = callback_value(cb_data, z)

    # Résolution du sous-problème
    SP = Model(GLPK.Optimizer)
    @variable(SP, 0 <= delta1[i in nodes, j in nodes] <= 1)
    @variable(SP, 0 <= delta2[i in nodes, j in nodes] <= 2)

    @objective(SP, Max, sum((delta1[i, j] * (th[i] + th[j]) + delta2[i, j] * th[i] * th[j]) * x_val[i, j] for (i, j) in A))
    @constraint(SP, sum(delta1[i, j] for (i, j) in A) <= T)
    @constraint(SP, sum(delta2[i, j] for (i, j) in A) <= T^2)

    optimize!(SP)

    if termination_status(SP) == MOI.OPTIMAL
        z_star = objective_value(SP)
        delta1_star = value.(delta1)
        delta2_star = value.(delta2)

        if z_star > z_val
            z_rhs = sum((delta1_star[i, j] * (th[i] + th[j]) + delta2_star[i, j] * th[i] * th[j]) * x[i, j] for (i, j) in A)
            MOI.submit(cb_data, MOI.LazyConstraint(), z >= z_rhs)
        end
    end
end

# Configurer le callback
MOI.set(model, MOI.LazyConstraintCallback(), cutting_plane_callback)

# Résolution
optimize!(model)

# Résultats
if termination_status(model) in [MOI.OPTIMAL, MOI.FEASIBLE]
    println("Objective value (coût total) : ", objective_value(model))
    println("Solutions des arcs sélectionnés :")
    for i in nodes, j in nodes
        if value(x[i, j]) > 0.5
            println("Arc ($i -> $j)")
        end
    end
    println("Quantité livrée : ", value.(u))
    println("Valeur robuste : ", value(z))
else
    println("Aucune solution faisable trouvée. Statut : ", termination_status(model))
end
