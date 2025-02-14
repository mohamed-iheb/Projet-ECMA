using JuMP
using Gurobi
using Glob

# Fonction pour lire un fichier d'instance au format donné
function read_instance(file_path::String)
    lines = readlines(file_path)

    n = parse(Int, split(lines[1], "=")[2])  
    t_values = split(strip(split(lines[2], "=")[2]), ";")  
    th = parse.(Int, split(strip(split(lines[3], "=")[2]), r"[\[\], ]", keepempty=false))  
    T = parse(Int, split(lines[4], "=")[2])  
    d = parse.(Int, split(strip(split(lines[5], "=")[2]), r"[\[\], ]", keepempty=false))  
    C = parse(Int, split(lines[6], "=")[2])  

    t = zeros(Int, n, n)
    for i in 1:n
        row_values = parse.(Int, split(strip(t_values[i]), r"[\[\], ]", keepempty=false))
        t[i, :] = row_values
    end

    return n, d, t, th, T, C
end

# Fonction pour résoudre une instance avec un critère d'arrêt temporel
function Resolution_Dualisation(n::Int, d::Vector{Int}, t::Matrix{Int}, C::Int, th::Vector{Int}, T::Int)
    nodes = 1:n
    A = [(i, j) for i in nodes, j in nodes if i != j]

    model = Model(Gurobi.Optimizer)
    
    # Définition de la limite de temps (10 s)
    set_optimizer_attribute(model, "TimeLimit", 10)

    # Définition des variables
    @variable(model, x[i in nodes, j in nodes], Bin) 
    @variable(model, u[i in 2:n] >= 0)  
    @variable(model, alpha1 >= 0)               
    @variable(model, alpha2 >= 0)  
    @variable(model, beta1[i in nodes, j in nodes] >= 0)   
    @variable(model, beta2[i in nodes, j in nodes] >= 0)

    # Fonction objectif
    @objective(model, Min, sum(t[i, j] * x[i, j] + beta1[i, j] + 2 * beta2[i, j] for (i, j) in A) + alpha1 * T + alpha2 * T^2)

    # Contraintes de tournée
    @constraint(model, [i in nodes; i != 1], sum(x[j, i] for j in nodes if j != i) == 1)
    @constraint(model, [i in nodes; i != 1], sum(x[i, j] for j in nodes if j != i) == 1)
    @constraint(model, sum(x[1, j] for j in nodes if j != 1) == sum(x[j, 1] for j in nodes if j != 1))

    # Contraintes de capacité
    @constraint(model, [i in nodes; i != 1], u[i] <= C - d[i])
    @constraint(model, [i in 2:n, j in 2:n; i != j], u[j] - u[i] >= d[i] - C * (1 - x[i, j]))
    @constraint(model, [j in 2:n], u[j] <= C * (1 - x[1, j]))
    @constraint(model, [i in nodes], x[i, i] == 0)

    # Contraintes de dualisation
    @constraint(model, [(i, j) in A], alpha1 + beta1[i, j] >= (th[i] + th[j]) * x[i, j])
    @constraint(model, [(i, j) in A], alpha2 + beta2[i, j] >= th[i] * th[j] * x[i, j])

    # Résolution du modèle
    optimize!(model)

    # Vérifier si la solution est optimale ou interrompue par la limite de temps
    solved = termination_status(model) == MOI.OPTIMAL

    if solved
        println("Statut de la solution : ", termination_status(model))
        println("Valeur optimale : ", objective_value(model))
        return true  # Instance résolue dans le temps imparti
    else
        println("Temps écoulé avant résolution complète")
        return false  # Instance non résolue dans le temps imparti
    end
end

# Fonction pour tester toutes les instances d'un dossier avec un critère de temps global
function test_all_instances_in_folder(folder_path::String)
    files = glob("*.txt", folder_path)
    solved_instances = 0  # Compteur d'instances résolues

    for file in files
        println("Test sur le fichier : ", file)
        n, d, t, th, T, C = read_instance(file)

        solved = Resolution_Dualisation(n, d, t, C, th, T)
        if solved
            solved_instances += 1
        end
    end

    println("\nNombre total d'instances résolues en 10 secondes : ", solved_instances)
end

# Test des fichiers d'instances dans le dossier
test_all_instances_in_folder("C:\\Users\\aziz_\\OneDrive\\Bureau\\Projet\\data")
