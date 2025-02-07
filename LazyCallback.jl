using JuMP
using CPLEX

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
function Resolution_LCb(n::Int64,d,t,C,th)
    # Ensemble des arcs
    nodes = 1:n
    A = [(i, j) for i in nodes, j in nodes if i != j]

    # Modèle maître
    model = Model(CPLEX.Optimizer)

    # Il est imposé d’utiliser 1 seul thread en Julia avec CPLEX pour utiliser les callbacks
    MOI.set(model, MOI.NumberOfThreads(), 1)

    # Variables
    @variable(model, x[i in nodes, j in nodes], Bin)  # Variables binaires pour les arcs
    @variable(model, u[i in 2:n] >= 0)  # Quantités livrées
    @variable(model, z >= 0)  # Variable de robustesse (bornée par 0)

    # Fonction objectif
    @objective(model, Min, z)

    # Contraintes de tournée

    @constraint(model,[i in nodes;i!=1], sum(x[j, i] for j in nodes if j != i) == 1)  # Un véhicule arrive
    @constraint(model,[i in nodes;i!=1], sum(x[i, j] for j in nodes if j != i) == 1)  # Un véhicule part
    
    @constraint(model, sum(x[1, j] for j in nodes if j != 1) == sum(x[j, 1] for j in nodes if j != 1))  # Retour au dépôt

    # Contraintes de capacité

    @constraint(model,[i in nodes;i!=1], u[i] <= C - d[i])
    


    @constraint(model,[i in 2:n, j in 2:n ;i!=j], u[j] - u[i] >= d[i] - C * (1 - x[i, j]))
            



    @constraint(model,[j in 2:n], u[j] <= C * (1 - x[1, j]))
    @constraint(model, [i in nodes], x[i, i] == 0)
    @constraint(model,z>= sum(t[i,j]*x[i,j] for (i,j) in A))

    


    # Fonction pour résoudre le sous-problème
    function solve_subproblem(x_val)
        submodel = Model(CPLEX.Optimizer)
        @variable(submodel, 0 <= δ1[i in nodes, j in nodes] <= 1)
        @variable(submodel, 0 <= δ2[i in nodes, j in nodes] <= 2)


        @constraint(submodel, sum(δ1[i, j] for (i, j) in A) <= T)
        @constraint(submodel, sum(δ2[i, j] for (i, j) in A) <= T^2)

        @objective(submodel, Max, sum([(t[i,j] + δ1[i, j] * (th[i] + th[j]) + δ2[i, j] * th[i] * th[j]) * x_val[i, j] for (i, j) in A]))

        optimize!(submodel)
        return value.(δ1), value.(δ2),objective_value(submodel)
    end

    # Fonction de callback
    function robust_callback(cb_data::CPLEX.CallbackContext, context_id::Clong)
        # Vérifier si le callback est appelé pour une solution entière
        if isIntegerPoint(cb_data,context_id)
            # Charger la solution entière courante
            CPLEX.load_callback_variable_primal(cb_data, context_id)
            # Récupérer les valeurs courantes de x
            x_val = [callback_value(cb_data, x[i, j]) for i in nodes, j in nodes]
            println("x_val = ", x_val)

            z_val = callback_value(cb_data, z)

            δ1_star, δ2_star,z_star = solve_subproblem(x_val)
            

            

        
            # Calculer la valeur de la contrainte de robustesse
            robust_value = sum((t[i,j]+ δ1_star[i, j] * (th[i] + th[j]) + δ2_star[i, j] * th[i] * th[j]) * x[i, j] for (i, j) in A)
            

        # Afficher la valeur de la contrainte de robustesse pour vérification
            println("Valeur de la contrainte de robustesse : ", robust_value)

        # Ajouter la contrainte de robustesse si nécessaire
            if z_star > z_val 
            cstr = @build_constraint(z >= robust_value)
            MOI.submit(model, MOI.LazyConstraint(cb_data), cstr)
            println("Added robust constraint: z >= ", robust_value)
            end

            
        end
    end

    function isIntegerPoint(cb_data::CPLEX.CallbackContext, context_id::Clong)
        # context_id == CPX_CALLBACKCONTEXT_CANDIDATE si le callback est
        # appelé dans un des deux cas suivants :
        # cas 1 - une solution entière a été obtenue; ou
        # cas 2 - une relaxation non bornée a été obtenue
        if context_id != CPX_CALLBACKCONTEXT_CANDIDATE
        return false
        end
        # Pour déterminer si on est dans le cas 1 ou 2, on essaie de récupérer la
        # solution entière courante
        ispoint_p = Ref{Cint}()
        ret = CPXcallbackcandidateispoint(cb_data, ispoint_p)
        # S’il n’y a pas de solution entière
        if ret != 0 || ispoint_p[] == 0
        return false
        else
        return true
        end
    end
    MOI.set(model, CPLEX.CallbackFunction(), robust_callback)
    optimize!(model)



    # Affichage des résultats
    status = termination_status(model)
    if status == MOI.OPTIMAL
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
        println("Aucune solution trouvée. Statut : ", status)
        if status == MOI.INFEASIBLE
            println("Le problème est infaisable. Vérifiez les contraintes et les paramètres.")
        elseif status == MOI.DUAL_INFEASIBLE || status == MOI.INFEASIBLE_OR_UNBOUNDED
            println("Le problème est non borné ou infaisable. Vérifiez la fonction objectif et les contraintes.")
        end
    end
    return value(z)
end
#Resolution_LCb(n,d,t,C,th)