using JuMP
using CPLEX

n = 10
t = [0 644 253 624 195 548 292 596 548 558; 644 0 530 876 804 611 922 931 521 409; 253 530 0 441 446 689 526 453 295 317; 624 876 441 0 770 1127 791 108 372 489; 195 804 446 770 0 545 122 721 740 753; 548 611 689 1127 545 0 652 1124 909 847; 292 922 526 791 122 652 0 727 815 841; 596 931 453 108 721 1124 727 0 451 563; 548 521 295 372 740 909 815 451 0 117; 558 409 317 489 753 847 841 563 117 0]
th = [8, 7, 6, 9, 5, 3, 2, 8, 1, 1]
T = 3
d = [0, 5, 5, 10, 3, 3, 1, 4, 8, 9]
C = 20

nodes = 1:n
A = [(i, j) for i in nodes, j in nodes if i != j]

# Fonction pour résoudre le sous-problème
function solve_subproblem(x_val)
    submodel = Model(CPLEX.Optimizer)
    @variable(submodel, 0 <= δ1[i in nodes, j in nodes] <= 1)
    @variable(submodel, 0 <= δ2[i in nodes, j in nodes] <= 2)

    @constraint(submodel, sum(δ1[i, j] for (i, j) in A) <= T)
    @constraint(submodel, sum(δ2[i, j] for (i, j) in A) <= T^2)

    @objective(submodel, Max, sum([(t[i,j] + δ1[i, j] * (th[i] + th[j]) + δ2[i, j] * th[i] * th[j]) * x_val[i, j] for (i, j) in A]))

    optimize!(submodel)
    return value.(δ1), value.(δ2), objective_value(submodel)
end

# Modèle maître initial (sans coupes)
model = Model(CPLEX.Optimizer)
@variable(model, x[i in nodes, j in nodes], Bin)
@variable(model, u[i in 2:n] >= 0)
@variable(model, z >= 0)

@objective(model, Min, z)

@constraint(model, [i in nodes; i != 1], sum(x[j, i] for j in nodes if j != i) == 1)
@constraint(model, [i in nodes; i != 1], sum(x[i, j] for j in nodes if j != i) == 1)
@constraint(model, sum(x[1, j] for j in nodes if j != 1) == sum(x[j, 1] for j in nodes if j != 1))

@constraint(model, [i in nodes; i != 1], u[i] <= C - d[i])
@constraint(model, [i in 2:n, j in 2:n; i != j], u[j] - u[i] >= d[i] - C * (1 - x[i, j]))
@constraint(model, [j in 2:n], u[j] <= C * (1 - x[1, j]))
@constraint(model, [i in nodes], x[i, i] == 0)

# Ensemble initial de coupes (vide au début)
cutting_planes = []

# Boucle de génération de coupes
cutting_planes = []
while true
    println("=== Nouvelle itération ===")

    # Optimisation du modèle maître
    optimize!(model)
    
    status = termination_status(model)
    if status != MOI.OPTIMAL
        println("Problème maître non optimal, arrêt.")
        break
    end

    x_val = value.(x)
    z_val = value(z)

    # Résolution du sous-problème
    δ1_star, δ2_star, z_star = solve_subproblem(x_val)

    println("z* (sous-problème) = ", z_star, ", z (maître) = ", z_val)

    # Vérification de la violation de la contrainte de robustesse
    robust_value = sum((t[i,j] + δ1_star[i, j] * (th[i] + th[j]) + δ2_star[i, j] * th[i] * th[j]) * x[i, j] for (i, j) in A)

    if z_star > z_val + 1e-6  # Tolérance numérique
        new_cut = @constraint(model, z >= robust_value)
        push!(cutting_planes, new_cut)
        println("Ajout d'une coupe : z >= ", robust_value)
    else
        println("Aucune coupe violée, arrêt de la boucle.")
        break
    end
end


# Affichage des résultats finaux
println("=== Solution Finale ===")
println("Objective value (coût total) : ", objective_value(model))
println("x values (arcs choisis) :")
for i in nodes, j in nodes
    if value(x[i, j]) > 0.5
        println("Arc ($i -> $j)")
    end
end
println("u values (quantité livrée) : ", value.(u))
println("z value (valeur robuste) : ", value(z))
