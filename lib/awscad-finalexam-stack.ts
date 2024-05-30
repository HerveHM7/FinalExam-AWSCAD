import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';


export class AwscadFinalexamStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create a VPC with a CIDR block of 10.30.0.0/16
    const vpc = new ec2.Vpc(this, 'MyVPC', {
      cidr: '10.30.0.0/16',
    });

    // Create an EC2 instance in the VPC using a Public Subnet
    const instance = new ec2.Instance(this, 'MyInstance', {
      vpc,
      instanceType: new ec2.InstanceType('t3.micro'), // Change to your desired instance type
      machineImage: new ec2.AmazonLinuxImage(), // Change to your desired AMI
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    // Create an SQS Queue
    const queue = new sqs.Queue(this, 'MyQueue', {
      visibilityTimeout: cdk.Duration.seconds(300),
    });

    // Create an SNS Topic
    const topic = new sns.Topic(this, 'MyTopic');

    // Create an AWS Secret with random values for username and password
    const secret = new secretsmanager.Secret(this, 'MySecret', {
      secretName: 'metrodb-secrets',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'tempuser' }),
        generateStringKey: 'password',
      },
    });
  }
}

const app = new cdk.App();
new AwscadFinalexamStack(app, 'AwscadFinalexamStack');

