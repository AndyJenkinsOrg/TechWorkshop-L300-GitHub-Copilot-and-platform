param location string
param environment string
param redisCacheName string = 'redis-zavasf-${environment}-${location}'

var redisSku = environment == 'dev' ? 'Basic' : 'Standard'
var redisCapacity = environment == 'dev' ? 0 : 1 // 0 for Basic C0, 1 for higher capacity
var redisFamily = environment == 'dev' ? 'C' : 'C'

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisCacheName
  location: location
  properties: {
    sku: {
      name: redisSku
      family: redisFamily
      capacity: redisCapacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    environment: environment
    application: 'ZavaStorefront'
  }
}

output redisCacheId string = redisCache.id
output redisCacheName string = redisCache.name
output redisCacheHostname string = redisCache.properties.hostName
output redisCachePort int = 6380
output redisCacheSslPort int = 6380
