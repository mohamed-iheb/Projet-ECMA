using JuMP
using CPLEX

# Données du problème
n = 5
t = [
    0 260 864 263 374;
    260 0 796 59 114;
    864 796 0 855 797;
    263 59 855 0 130;
    374 114 797 130 0
]
th = [6, 1, 2, 8, 1]  # Valeurs d'incertitudes
T = 6
d = [0, 6, 2, 5, 3]
C = 12

# Ensemble des arcs
nodes = 1:n
A = [(i, j) for i in nodes, j in nodes if i != j]

# Modèle maître
model = Model(CPLEX.Optimizer)


# Variables
@variable(model, x[i in nodes, j in nodes], Bin) 
@variable(model, u[i in 2:n] >= 0)  
@variable(model, alpha1 >= 0)               
@variable(model, alpha2 >= 0)  
@variable(model, beta1[i in nodes,j in nodes]  >= 0  )   
@variable(model, beta2[i in nodes,j in nodes]  >= 0  )    



# Fonction objectif
@objective(model, Min, sum(t[i, j] * x[i, j] + beta1[i,j] + 2*beta2[i,j] for (i, j) in A ) + alpha1 * T + alpha2 * T^2)

# Contraintes de tournée
@constraint(model, [i in nodes; i != 1], sum(x[j, i] for j in nodes if j != i) == 1)
@constraint(model, [i in nodes; i != 1], sum(x[i, j] for j in nodes if j != i) == 1)
@constraint(model, sum(x[1, j] for j in nodes if j != 1) == sum(x[j, 1] for j in nodes if j != 1))

# Contraintes de capacité
@constraint(model, [i in nodes; i != 1], u[i] <= C - d[i])
@constraint(model, [i in 2:n, j in 2:n; i != j], u[j] - u[i] >= d[i] - C * (1 - x[i, j]))
@constraint(model, [j in 2:n], u[j] <= C * (1 - x[1, j]))
@constraint(model, [i in nodes], x[i, i] == 0)
#contraintes de dualisation
@constraint(model,[(i,j) in A], alpha1 + beta1[i,j] >=  (th[i] + th[j]) * x[i, j])
@constraint(model,[(i,j) in A], alpha2 + beta2[i,j] >=  th[i] * th[j] * x[i, j])

# Résolution
optimize!(model)

# Affichage des résultats
println("Statut de la solution : ", termination_status(model))
println("Valeur optimale : ", objective_value(model))

println("\nVariables x :")
for i in nodes, j in nodes
    if value(x[i, j]) > 0.5
        println("x[$i, $j] = ", value(x[i, j]))
    end
end

println("\nVariables u :")
for i in 2:n
    println("u[$i] = ", value(u[i]))
end

println("\nValeurs des alpha et beta :")
println("alpha1 = ", value(alpha1))
println("alpha2 = ", value(alpha2))
for i in nodes, j in nodes
    println("beta1[$i, $j] = ", value(beta1[i, j]), ", beta2[$i, $j] = ", value(beta2[i, j]))
end
