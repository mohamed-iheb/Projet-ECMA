using JuMP
using CPLEX
using Dates
include("data/n_5-euclidean_false")
t1=Dates.now()

function Resolution_MTZ(n::Int64,d,t,C)
    
    m = Model(CPLEX.Optimizer)
    set_silent(m)
    
    # Variable binaire x[i, j] : 1 si l'arc (i, j) est utilisé dans le chemin optimal, 0 sinon
    @variable(m, x[1:n, 1:n], Bin)
    @variable(m, u[1:n]>=0, Int) 
    @variable(m, k[1:n]>=0, Int) 

    # Conservation de flux
    @constraint(m, [i in 2:n],sum(x[i, j] for j in 1:n) == 1)
    @constraint(m, [i in 2:n],sum(x[j, i] for j in 1:n) == 1)
    
    #  élimination de cycles
    #@constraint(m, u[1] == 0)
    @constraint(m, [i in 1: n,j in 2: n], u[i]+x[i,j]-2*n*(1-x[i,j]) <= u[j])
    
    # satisfaction de demande (jarrab j!=1)
    @constraint(m, [i in 1: n,j in 1: n], k[i] <= C)
    #@constraint(m, k[1] == 0)
    #@constraint(m, [i in 2: n], k[i]==d[i]+ sum(x[j, i]*k[j] for j in 1:n))
    #@constraint(m, [i in 1: n], u[i] <= 2)
    M = 1000  # Constante suffisamment grande pour la linéarisation

    @variable(m, y[1:n, 2:n] >= 0)   # Variables continues pour la linéarisation

    # Contraintes de linéarisation pour y[j, i] = x[j, i] * k[j]
    @constraint(m, [i in 2:n, j in 1:n], y[j, i] <= M * x[j, i])
    @constraint(m, [i in 2:n, j in 1:n], y[j, i] <= k[j])
    @constraint(m, [i in 2:n, j in 1:n], y[j, i] >= k[j] - M * (1 - x[j, i]))

    # Nouvelle contrainte reformulée
    @constraint(m, [i in 2:n], k[i] == d[i] + sum(y[j, i] for j in 1:n))

    
    # Objectif : minimiser la distance totale
    @objective(m, Min, sum(t[i,j] * x[i, j] for i in 1:n for j in 1:n))
    
    # Résolution
    optimize!(m)
    
    # Récupérer les résultats
    vx = value.(x)
 
    status = termination_status(m)
    isOptimal = status == MOI.OPTIMAL
    println(vx)
    println("Solution optimale trouvée : ", isOptimal)
    println("la distance optimale trouvé :",objective_value(m))
 
    afficher(0,vx,1,n,1)
    return objective_value(m)
end
function afficher(s,vx,i,n,i_f)
    for j in 1:n
        if vx[i,j]==1 
            vx[i,j]=0
            s=s+1
            print(i," -> ")
            if j==1 print(1, "\n") end
            afficher(s,vx,j,n,1)
        end
    end
end

# Pour une donnée manuelle des instances :
"""n = 5
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
C = 12"""

# Optimisation
Resolution_MTZ(n, d, t, C)

# Temps de calcul
t2=Dates.now()
println("Temps de calcul= ",t2-t1)
