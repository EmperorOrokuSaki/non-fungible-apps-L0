import Web3 from 'web3';
import * as abiFile from '../../../contracts/deployments/goerli/FleekERC721.json';

const contract_address = abiFile.address;
const abi = abiFile.abi as any;

const web3 = new Web3('https://rpc.goerli.mudit.blog');

export const nfaContract = new web3.eth.Contract(abi, contract_address);
