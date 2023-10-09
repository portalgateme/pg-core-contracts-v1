import { KeyringConfig } from './types'

export default {
  // mainnet config
  '1': {
    ruleRegistry: '0x6B89701bF931F783A8062AA99EDD2fD442Bb2b09',
    policyManager: '0x4C5775343d4a9f0eB3A4777ed340A3bf73c0abC9',
    identityTree: '0xA54e48f5c49A3B4B02771a1Cac78e194C555eb34',
    walletCheck: '0x163EBd5042F3Cb4f99DC6Ed6750c85d51b3B1437',
    forwarder: '0x161e8A42FaEC8f2c254B8444F9fa771d79AA3D27',
    keyringCredentials: '0x22F4f112179CD6cca7152BBA306F775c74e068D4',
    userPolicies: '0x8cE1fd061C1D50466111df622077925C5e62BaeE',
    exemptionsManager: '0x5D8ABdFA37eb4716374C139279cc9b5116bc4e2D',
  },
  // goerli config
  '5': {
    ruleRegistry: '0x6B89701bF931F783A8062AA99EDD2fD442Bb2b09',
    policyManager: '0x4C5775343d4a9f0eB3A4777ed340A3bf73c0abC9',
    identityTree: '0xA54e48f5c49A3B4B02771a1Cac78e194C555eb34',
    walletCheck: '0x163EBd5042F3Cb4f99DC6Ed6750c85d51b3B1437',
    forwarder: '0x161e8A42FaEC8f2c254B8444F9fa771d79AA3D27',
    keyringCredentials: '0x22F4f112179CD6cca7152BBA306F775c74e068D4',
    userPolicies: '0x8cE1fd061C1D50466111df622077925C5e62BaeE',
    exemptionsManager: '0x5D8ABdFA37eb4716374C139279cc9b5116bc4e2D',
  },
  '31337': {
    ruleRegistry: '0x6B89701bF931F783A8062AA99EDD2fD442Bb2b09',
    policyManager: '0x4C5775343d4a9f0eB3A4777ed340A3bf73c0abC9',
    identityTree: '0xA54e48f5c49A3B4B02771a1Cac78e194C555eb34',
    walletCheck: '0x163EBd5042F3Cb4f99DC6Ed6750c85d51b3B1437',
    forwarder: '0x161e8A42FaEC8f2c254B8444F9fa771d79AA3D27',
    keyringCredentials: '0x22F4f112179CD6cca7152BBA306F775c74e068D4',
    userPolicies: '0x8cE1fd061C1D50466111df622077925C5e62BaeE',
    exemptionsManager: '0x5D8ABdFA37eb4716374C139279cc9b5116bc4e2D',
  },
} as KeyringConfig

export const ONE_DAY_IN_SECONDS = 24 * 60 * 60
export const MINIMUM_MAX_CONSENT_PERIOD = 60 * 60 // 1 hour
export const MAXIMUM_CONSENT_PERIOD = ONE_DAY_IN_SECONDS * 120 // 120 days;
