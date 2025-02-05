{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
-- | Reports the results of the solver
module Rhodium.Solver.SolveResult(
    SolveResult(..),
    emptySolveResult,
    graphToSolveResult
) where

import Rhodium.TypeGraphs.Graph
import Rhodium.TypeGraphs.GraphUtils hiding (getSubstitutionFromGraph)
import Rhodium.TypeGraphs.GraphProperties
import Rhodium.Solver.Rules

import Data.List
import Data.Maybe

import qualified Data.Map as M

-- | The result of the solver
data SolveResult touchable types constraint ci = SolveResult{
    touchables :: [touchable],
    substitution :: [(touchable, types)],
    smallGiven :: [constraint],
    errors :: [(ci, constraint, ErrorLabel)],
    graph :: TGGraph touchable types constraint ci
}

-- | An empty result
emptySolveResult :: SolveResult touchable types constraint ci
emptySolveResult = SolveResult [] [] [] [] emptyTGGraph

-- | Convert a graph to a SolveResult
graphToSolveResult ::  (Show ci, HasConstraintInfo constraint ci, Eq types, Eq touchable, Show types, Show touchable, Show constraint, IsEquality axiom types constraint touchable, CanCompareTouchable touchable types) 
                   => [axiom]
                   -> Bool 
                   -> [touchable] 
                   -> TGGraph touchable types constraint ci 
                   -> SolveResult touchable types constraint ci
graphToSolveResult axs allowTouchable ts g = let
    bg = nub $ filter (\g'' -> length g'' == 1) $ map getGroupFromEdge $ filter isConstraintEdge $ M.elems (edges g)
    g' =  markEdgesUnresolved (head bg) g
    (subEdges, resEdges) = partition (isSubstitutionEdge allowTouchable axs g') 
        (if allowTouchable then getUnresolvedConstraintEdges' g' else getUnresolvedConstraintEdges (head bg) g')
    touchables' = map fst $ getTouchablesFromGraph allowTouchable g'
    substitution' = getSubstitutionFromGraph (nub $ ts ++ touchables') subEdges
    smallGiven' = getSmallGiven g'
    errors' = getErrorsFromGraph g' resEdges
    in SolveResult (nub $ ts ++ touchables') substitution' smallGiven' errors' g'



isSubstitutionEdge :: (Show types, Show touchable, Show constraint, IsEquality axiom types constraint touchable) 
                   => Bool
                   -> [axiom]
                   -> TGGraph touchable types constraint ci 
                   -> TGEdge constraint 
                   -> Bool
isSubstitutionEdge allowTouchable axs g edge     | not allowTouchable && (isEdgeGiven edge || priority (edgeCategory edge) == 0) = True
                                                | not (allowInSubstitution axs (map fst $ getTouchablesFromGraph False g) (getConstraintFromEdge edge)) = False
                                                | not allowTouchable && not (isConstraintTouchable 0 g edge) = False
                                                | not allowTouchable && priority (edgeCategory edge) > 1 = False
                                                | otherwise = True

getSubstitutionFromGraph :: (Eq types, Show touchable, Show types, Show constraint, IsEquality axiom types constraint touchable, CanCompareTouchable touchable types) => [touchable] -> [TGEdge constraint] -> [(touchable, types)]
getSubstitutionFromGraph ts constraints = let 
        initialSub = map (\v -> (v, convertTouchable v)) ts
        splitConstraints = map (splitEquality . getConstraintFromEdge) constraints
        findSub tp = fromMaybe tp (lookup tp splitConstraints) 
    in map (\(v, t) -> (v, findSub t)) initialSub

           
getErrorsFromGraph :: (Show ci, HasConstraintInfo constraint ci, IsEquality axiom types constraint touchable, Show constraint, Show types, Show touchable) => TGGraph touchable types constraint ci -> [TGEdge constraint] -> [(ci, constraint, ErrorLabel)]
getErrorsFromGraph g res = let 
        errorLabels1 = mapMaybe (\e -> case getIsIncorrect e of
                    Nothing -> Nothing 
                    Just ic -> Just (Nothing, getConstraintFromEdge e, ic)
            )$ filter isConstraintEdge $ M.elems $ edges g
        errorLabels2 = map (\e -> (getConstraintInfo (getConstraintFromEdge e), getConstraintFromEdge e, ErrorLabel $ "Residual constraint: " ++ show (getConstraintFromEdge e))) res     
        errorLabels = errorLabels1 ++ errorLabels2
        mapLabels = mapMaybe (\(mci, cons, label) -> case mci of 
                    Just ci -> Just (ci, cons, label)
                    Nothing -> Just (error ("No constraint information for " ++ show label ++ " on edge " ++ show cons), cons, label)
                ) $  maybe errorLabels (map (\(_, ci, cons, label) -> (Just ci, cons, label))) (resolvedErrors g)
        in if not (null errorLabels) && null mapLabels then error "All errors incorrectly removed" else mapLabels

getSmallGiven :: Show constraint => TGGraph touchable types constraint ci -> [constraint]
getSmallGiven g = map getConstraintFromEdge $ filter (\c -> isConstraintEdge c && isEdgeGiven c && isUnresolvedConstraintEdge [0] c) $ M.elems (edges g)

-- | An instance to show a SolveResult
instance (Show touchable, Show types, Show constraint, Show ci) => Show (SolveResult touchable types constraint ci) where
    show sr = unlines $ 
        "SolveResult: " :
        indent (
                "Touchable" : 
                indent (map show (touchables sr))
            )
        ++ 
        indent (
            "Substitution" : 
            indent (map show (substitution sr))
        )
        ++ 
        indent (
            "Small given" : 
            indent (map show (smallGiven sr))
        )
        ++ 
        indent (
            "Errors" : 
            indent (map (show. (\(_, _, l) -> l)) (errors sr))
        )
        where
            indent = map ("\t"++)

