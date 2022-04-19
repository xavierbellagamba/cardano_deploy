# Cardano Deploy
Hi! In this repo, we propose a semi-automated approach that facilitates the deployment of Cardano node on Linux machines. We believe node operations should be made more broadly available. This aims at democratizing pool operations and should have the following positive side effects:
- Improve the network security (the more nodes, the more resistant to sybil attacks)
- Increase network decentralization (which is the final aim of public blockchain)
- Enhance the profit distribution (reinforcing equality between participants)

## Steps to complete before launching the script
1. Setup the VMs (see min configuration below)
2. Assign static public IPs to the servers. On AWS, you can follow [these instructions](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-associate-static-public-ip/?nc1=h_ls)
3. Setup the git repository for metadata on [Github](https://github.com/)
4. Create and upload the metadata (see example below) to the repository using [TinyURL](https://tinyurl.com/app)
5. The metadata file must also be stored where the autodeploy.sh file will be executed.
6. Amend the deployment script to suit your deployment pattern and configurated VMs.

### Example file
The file should be a json file following the below pattern:
<code>
{
  "name": "versorium",
  "description": "The versorium.io pool",
  "ticker": "VRSM",
  "homepage": "https://versorium.io"
}
</code>

## Minimum configuration
Two to three machines are necessary to operate a staking pool. 
The proposed automated deployment approach requires these machines to have the following requirements:

- OS: Ubuntu 20+
- CPU: 2 cores @ 1.8GHz (x86_64 arch)
- RAM: 16GB
- Storage: 30GB (preferably SSD)
- High-speed and stable internet connection

Machines can be VMs from a cloud provider or personal servers. 
On AWS, this configuration is best represented by the m4.xlarge EC2 machines.

## How to use the deployment scripts
The successful deployment of a Cardano stake pool using this approach can be decomposed into XXX steps:
1. Run the script on the relay infrastructure (should complete without intervention)
2. Check relay deployment by checking the gLiveView (cmd: <code>glv</code>)
3. Run the script on the core node infrastructure (make sure the prerequisits are setup)
4. Once signalled by the program, sendthe funds necessary for the registration
5. Check the core node deployment by checking the gLiveView and [pooltool.io](https://pooltool.io/)

## Disclaimer
- Security aspects are not covered. Aspiring pool operators should do their own research on the matter and apply state-of-the-art security.
- The authors do not guarantee the success of the deployment
- The authors are not responsible for any loss of tokens or cash caused by the deployment and operation of the stake pool
- This approach only aims at facilitating the deployment of Cardano node, making it more accessible for non-expert users
- In summary, this automated deployment script is here to be used freely, but at your own risk and cost. 
