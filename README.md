# sessel

![Image of Yaktocat](sessel.png)

Sessel - an AWS SES configuration tool

The idea behind this gem is to privide a way to automate configuration of Simple Email Service in AWS, so that the complete solution that one builds in AWS could be stored in the repository and deployed automatically.

## Installation

In order to install the gem call

    gem install sessel
    
Alternatively if you use bundle you can add an entry to the `Gemfile`
    
## Usage

The first step is to create the sessel.yaml. Sessel offers commands that interatively ask you for all the required information.

    sessel add receipt_rule <SOLUTION_NAME>
    
or 
    
    sessel add configuration_set <SOLUTION_NAME>
    
       
Following the instructions in both cases will result in relevant resources being created in your AWS account and `sessel.yaml` being updated.
In order to apply the settings again one can call 

    sessel apply
    
       
    