-- | The options the solver uses
module Rhodium.Solver.SolveOptions where

import Rhodium.Blamer.Heuristics
import Rhodium.Blamer.ResidualHeuristics
import Rhodium.Blamer.Path

-- | The solver options
data SolveOptions m axiom touchable types constraint ci diagnostic = SolveOptions{
    typeHeuristics :: Path m axiom touchable types constraint ci -> [Heuristic m axiom touchable types constraint ci diagnostic],
    residualHeuristics :: ResidualHeuristics m axiom touchable types constraint ci diagnostic,
    typeErrorDiagnosis :: Bool, 
    includeTouchables :: Bool,
    teMustShowTrace :: Bool
    }

-- | No Solver options
emptySolveOptions :: SolveOptions m axiom touchable types constraint ci diagnostic
emptySolveOptions = SolveOptions {
        typeHeuristics = const [],
        residualHeuristics = const [],
        typeErrorDiagnosis = True,
        includeTouchables = False,
        teMustShowTrace = True
    }

-- | Disables the process of type error diagnosis. Can be used when the only information of interest is success or failure, not which exact error has occured.
disableErrorDiagnosis :: SolveOptions m axiom touchable types constraint ci diagnostic -> SolveOptions m axiom touchable types constraint ci diagnostic
disableErrorDiagnosis options = options{
    typeErrorDiagnosis = False
    }

-- | Ignore any problems with touchability, might cause incorrect programs to be accepted, but can be used to inspect the types inside existentital constraints    
ignoreTouchables :: SolveOptions m axiom touchable types constraint ci diagnostic -> SolveOptions m axiom touchable types constraint ci diagnostic
ignoreTouchables options = options{
    includeTouchables = True
}
