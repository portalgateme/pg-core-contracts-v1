// @ts-ignore
import MerkleTree from 'fixed-merkle-tree'
import { poseidonHash2 } from './utils'
import { BN } from 'ethereumjs-util'

export const generateTree = (
  treeLevels: number,
  elements: BN[] = [],
  hashFunction: Function = poseidonHash2,
) => new MerkleTree(treeLevels, elements, { hashFunction })
