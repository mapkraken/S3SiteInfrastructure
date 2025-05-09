aws rds create-db-snapshot \
  --db-instance-identifier ${self:provider.stage}-koop-postgis \
  --db-snapshot-identifier ${self:provider.stage}-koop-postgis-snapshot-$(date +%Y%m%d%H%M%S)