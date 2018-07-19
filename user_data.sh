#!/bin/bash
                          # Install Tools
                          sudo sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/epel.repo
                          sudo yum install -y aws-cfn-bootstrap libstdc++-devel gcc-c++ fuse fuse-devel curl-devel libxml2-devel mailcap automake  openssl-devel git
                          # create mount folder
                          mkdir /mnt/HEDWIG_DATA
                        - !Sub |
                          # Install S3FS
                          git clone https://github.com/s3fs-fuse/s3fs-fuse
                          cd ./s3fs-fuse
                          ./autogen.sh
                          ./configure --prefix=/usr --with-openssl
                          make
                          sudo make install
                        - !Sub |
                          # Once S3FS is installed, set up the credentials
                          echo ${S3credentials} >> /.passwd-s3fs
                          sudo echo 'user_allow_other'>>/etc/fuse.conf
                          # Add permission to credential file to fix should not have others permissions
                          chmod 600 /.passwd-s3fs
                          chown 500 /.passwd-s3fs
                          # Update uid permission to fix the folders r/w permission in docker
                          sudo chown 500 /mnt/HEDWIG_DATA/
                          # Mount the S3 bucket
                          s3fs ${S3Bucket} /mnt/HEDWIG_DATA/ -o uid=500,umask=0022,gid=500 -o passwd_file=/.passwd-s3fs  -o allow_other
                          # Docker must be restarted or it can not see the S3FS mount
                          service docker restart
                        - !Sub |
                          # Configure ECS
                          mkdir -p /etc/ecs
                          echo ECS_CLUSTER=${ECSCluster} >> /etc/ecs/ecs.config
                          /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource  EcsInstanceAsg --region ${AWS::Region}
