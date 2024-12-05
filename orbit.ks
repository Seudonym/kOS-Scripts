function main {
    // ascend(75000).
    circularize().
}

function ascend {
    // Ascends to raise apoapsis to the specified altitude.
    parameter pAltitude.

    when maxThrust <= 0.0 then {
        autoStage().
        return true.
    }

    sas off.
    //* TODO: Implement proper ascent guidance.
    lock steering to heading(90, 90 * (1 - altitude / pAltitude)).
    lock throttle to (apoapsis / pAltitude)^0.1.

    wait until apoapsis >= pAltitude.

    unlock steering.
    unlock throttle.
    return.
}

function autoStage {
    // Automatically stages the rocket when the current stage runs out of fuel.
    // params: none.
    // returns: nothing.
    until maxThrust > 0.0 {
        wait 1.
        stage.
    }

    return.
}

function circularize {
    local nodeParams is list(time:seconds + max(eta:apoapsis, 30), 0, 0, 0).

    until eccentricityUtility(nodeParams) > 0.95 {
        local bestParams is improve(eccentricityUtility@, nodeParams).
        set nodeParams to bestParams.
        print "Improving... " + eccentricityUtility(nodeParams).
    }

    local plannedMnv is node(nodeParams[0], nodeParams[1], nodeParams[2], nodeParams[3]).
    executeManeuver(plannedMnv).
    
}

// TODO: A
function improve {
    // Improves the input state by incrementing or decrementing each element by 1.
    // params: utilityFunction: function, inputState: list.
    // returns: bestState: list.
    parameter utilityFunction, inputState.

    local candidates is list().
    from {local i is 0.} until i = inputState:length step {set i to i + 1.} do {
        local candidate is inputState:copy.
        set candidate[i] to candidate[i] + 10.
        candidates:add(candidate).

        set candidate to inputState:copy.
        set candidate[i] to candidate[i] - 10.
        candidates:add(candidate).
    }

    local bestState is inputState.
    local bestUtility is utilityFunction(inputState).

    for candidate in candidates {
        local utility is utilityFunction(candidate).
        if utility > bestUtility {
            set bestUtility to utility.
            set bestState to candidate.
        }
    }

    return bestState.
}

// Utility functions
function eccentricityUtility {
    // Calculates the utility of the current orbit based on its eccentricity.
    // params: nodeParams: list.
    // returns: utility: scalar.
    parameter nodeParams.

    local mnvNode is node(nodeParams[0], nodeParams[1], nodeParams[2], nodeParams[3]).
    add mnvNode.
    
    local v_apoapsis is mnvNode:orbit:apoapsis + body:radius.
    local v_periapsis is mnvNode:orbit:periapsis + body:radius.

    local numerator is v_apoapsis^2 - v_periapsis^2.
    local utility is 0.
    if numerator > 0 {
        set utility to sqrt(numerator) / v_apoapsis.
    } else {
        set utility to sqrt(-numerator) / v_periapsis.
    }
    remove mnvNode.

    return 1 - utility.
}

// TODO: Use Tsiolkovsky rocket equation to calculate deltaV.
function executeManeuver {
    // Executes the maneuver node.
    // params: node: ManeuverNode
    // returns: nothing.
    parameter mnvNode.

    add mnvNode.

    local maxAccel is ship:maxThrust / ship:mass.
    local burnTime is mnvNode:deltaV:mag / maxAccel.

    wait until mnvNode:eta <= (burnTime / 2 + 30).
    lock steering to mnvNode:deltaV.
    wait until mnvNode:eta <= (burnTime / 2).

    until mnvNode:deltaV:mag <= 2 {
        lock throttle to 1.
    }

    unlock steering.
    unlock throttle.
    remove mnvNode.
    return.
}

main().