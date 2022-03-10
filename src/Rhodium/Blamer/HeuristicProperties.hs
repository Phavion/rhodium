{-# LANGUAGE MultiParamTypeClasses #-}
-- | Module for describing properties of heuristics or properties that heuristics use
module Rhodium.Blamer.HeuristicProperties where
    
import Rhodium.Solver.Rules
import Rhodium.TypeGraphs.Graph

newtype TypeErrorOptions = TEOptions {
    showTrace :: Bool
}
-- | Can create the type error
class TypeErrorInfo m constraint ci where
    createTypeError :: TypeErrorOptions -> TGEdge constraint -> ErrorLabel -> constraint -> ci -> m ci