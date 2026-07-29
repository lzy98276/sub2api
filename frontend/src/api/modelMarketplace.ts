import { apiClient } from './client'
import type { UserSupportedModelPricing } from './channels'

export interface ModelMarketplaceGroup {
  id: number
  name: string
  platform: string
  rate_multiplier: number
}

export interface ModelMarketplaceModel {
  name: string
  platform: string
  provider: string
  pricing: UserSupportedModelPricing | null
  groups: ModelMarketplaceGroup[]
}

export interface ModelMarketplaceResponse {
  models: ModelMarketplaceModel[]
}

export async function getModelMarketplace(options?: { signal?: AbortSignal }): Promise<ModelMarketplaceResponse> {
  const { data } = await apiClient.get<ModelMarketplaceResponse>('/channels/model-marketplace', {
    signal: options?.signal,
  })
  return data
}
