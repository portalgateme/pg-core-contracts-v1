// @ts-ignore
import MerkleTree from 'fixed-merkle-tree'
import { poseidonHash2 } from './utils'

export const generateTree = (treeLevels: number, hashFunction: Function = poseidonHash2) =>
  new MerkleTree(treeLevels, [], { hashFunction })
