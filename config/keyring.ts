import { KeyringConfig } from './types'

export default {
  // mainnet config
  '1': {
    ruleRegistry: '0xcb86922980610931B9fAe65815cE96baaFc7b366',
    policyManager: '0x685BC814f9ee40fA7bD35588ac6a9E882A2345F3',
    identityTree: '0xa15aaF6987A8E60c0a00eF81fdf10012859878BC',
    walletCheck: '0x1c7b604a7d738eCbB0F5e44718adE4bC58A454aA',
    forwarder: '0x2f5885a892cFf774Df6051E70baC6Ce552dC7E2a',
    keyringCredentials: '0x8a16F136121FD53B5c72c3414b42299f972c9c67',
    userPolicies: '0x77985FD28C1334c46CA45bEAC73f839Fd2860E7c',
    exemptionsManager: '0xAA7E8090a26464181E188848Eea5Ac5b81ed6B93',
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
