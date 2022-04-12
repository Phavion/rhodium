-- | The state of the type graph solver
module Rhodium.TypeGraphs.TGState(
    runTG,
    emptyTGState,
    TGStateM,
    TGState(..)
) where



import Control.Monad.Trans.State

import Rhodium.TypeGraphs.Graph
import Rhodium.Solver.Rules

import Rhodium.Blamer.HeuristicState

-- | Represents the state of the type graph solver
type TGStateM m axiom touchable types constraint ci diagnostic = StateT (TGState m axiom touchable types constraint ci diagnostic) m

-- | Runs TGStateM monad
runTG :: Monad m => TGStateM m axiom touchable types constraint ci diagnostic a -> m a
runTG s = evalStateT s emptyTGState 

-- | Stores all meta information about a type graph
data TGState m axiom touchable types constraint ci diagnostic = TGState{
    axioms :: [axiom],
    diagnostics :: [diagnostic],
    vertexIndex :: Int,
    edgeIndex :: Int,
    groupIndex :: Int,
    graph :: TGGraph touchable types constraint ci,
    isGraphRuleApplied :: Bool,
    rulesApplied :: [(Rule, [constraint], String)],
    currentPriority :: Priority,
    givenVariables :: [touchable],
    heuristicState :: HeuristicState m axiom touchable types constraint ci diagnostic,
    logs :: [String],
    originalInput :: ([constraint], [constraint], [touchable])
} deriving Show

-- | Return an empty TGState
emptyTGState :: TGState m axiom touchable types constraint ci diagnostic
emptyTGState = TGState{
    axioms = [],
    diagnostics = [],
    graph = emptyTGGraph,
    vertexIndex = 0,
    edgeIndex = 0,
    groupIndex = 0,
    isGraphRuleApplied = False,
    currentPriority = 0,
    givenVariables = [],
    rulesApplied = [],
    heuristicState = emptyHeuristicState,
    logs = [],
    originalInput = ([], [], [])
}




