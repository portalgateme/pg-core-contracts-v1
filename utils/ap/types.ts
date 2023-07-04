export const RewardExtData = {
  RewardExtData: {
    relayer: 'address',
    encryptedAccount: 'bytes',
  },
}
export const AccountUpdate = {
  AccountUpdate: {
    inputRoot: 'bytes32',
    inputNullifierHash: 'bytes32',
    outputRoot: 'bytes32',
    outputPathIndices: 'uint256',
    outputCommitment: 'bytes32',
  },
}
export const RewardArgs = {
  RewardArgs: {
    rate: 'uint256',
    fee: 'uint256',
    instance: 'address',
    rewardNullifier: 'bytes32',
    extDataHash: 'bytes32',
    depositRoot: 'bytes32',
    withdrawalRoot: 'bytes32',
    extData: RewardExtData.RewardExtData,
    account: AccountUpdate.AccountUpdate,
  },
}

export const WithdrawExtData = {
  WithdrawExtData: {
    fee: 'uint256',
    recipient: 'address',
    relayer: 'address',
    encryptedAccount: 'bytes',
  },
}
